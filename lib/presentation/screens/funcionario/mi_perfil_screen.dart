import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../../../core/supabase/supabase_config.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';
import 'login_screen.dart';

class MiPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MiPerfilScreen({super.key, required this.userData});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _editando = false;
  bool _guardando = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _cambiarPassword = false;

  Uint8List? _nuevaFotoBytes;
  bool _subiendoFoto = false;

  int _totalCasos = 0;
  int _casosRevision = 0;
  int _casosResueltos = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarStats();
  }

  void _cargarDatos() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final fd = authService.funcionarioData;
    _nombreController.text =
        fd?['nombre']?.toString() ?? widget.userData['nombre']?.toString() ?? '';
    _cargoController.text =
        fd?['cargo']?.toString() ?? widget.userData['cargo']?.toString() ?? '';
    _departamentoController.text = fd?['departamento']?.toString() ??
        widget.userData['departamento']?.toString() ??
        '';
  }

  Future<void> _cargarStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final funcionarioId = authService.funcionarioData?['id'];

      if (funcionarioId == null) return;

      final response = await _supabase
          .from('denuncias')
          .select('estado')
          .eq('funcionario_id', funcionarioId);

      final List<dynamic> data = response;

      setState(() {
        _totalCasos = data.length;
        _casosRevision =
            data.where((d) => d['estado'] == 'revision').length;
        _casosResueltos =
            data.where((d) => d['estado'] == 'resuelta').length;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cargoController.dispose();
    _departamentoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 90,
      );

      if (picked == null) return;

      Uint8List bytes;

      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      } else {
        try {
          final cropped = await ImageCropper().cropImage(
            sourcePath: picked.path,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 88,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Ajustar foto de perfil',
                toolbarColor: AppConfig.azulOscuro,
                toolbarWidgetColor: Colors.white,
                backgroundColor: Colors.black,
                activeControlsWidgetColor: AppConfig.azulClaro,
                lockAspectRatio: true,
                hideBottomControls: false,
                initAspectRatio: CropAspectRatioPreset.square,
              ),
              IOSUiSettings(
                title: 'Ajustar foto de perfil',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
                rotateButtonsHidden: false,
                rotateClockwiseButtonHidden: false,
              ),
            ],
          );

          if (cropped != null) {
            bytes = await cropped.readAsBytes();
          } else {
            bytes = await picked.readAsBytes();
          }
        } catch (_) {
          bytes = await picked.readAsBytes();
        }
      }

      setState(() => _nuevaFotoBytes = bytes);
    } catch (e) {
      _showError('No se pudo seleccionar la imagen');
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppConfig.grisMedio,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.azulClaro.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppConfig.azulClaro),
                ),
                title: const Text('Tomar foto',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.verde.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppConfig.verde),
                ),
                title: const Text('Galería / Archivos',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.rojo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.delete_rounded, color: AppConfig.rojo),
                ),
                title: const Text('Eliminar foto',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppConfig.rojo)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _nuevaFotoBytes = null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _subirFoto(String funcionarioId) async {
    if (_nuevaFotoBytes == null) return null;
    final path =
        'funcionarios/funcionario_${funcionarioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('avatares').uploadBinary(
          path,
          _nuevaFotoBytes!,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _supabase.storage.from('avatares').getPublicUrl(path);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cambiarPassword) {
      if (_passwordController.text.length < 8) {
        _showError('La contraseña debe tener mínimo 8 caracteres');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Las contraseñas no coinciden');
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final funcionarioId = authService.funcionarioData?['id'];
      if (funcionarioId == null) throw Exception('No se encontró el perfil');

      String? nuevaFotoUrl;
      if (_nuevaFotoBytes != null) {
        setState(() => _subiendoFoto = true);
        nuevaFotoUrl = await _subirFoto(funcionarioId.toString());
        setState(() => _subiendoFoto = false);
      }

      final Map<String, dynamic> updateData = {
        'nombre': _nombreController.text.trim(),
        'cargo': _cargoController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'actualizado_en': DateTime.now().toIso8601String(),
      };

      if (nuevaFotoUrl != null) {
        updateData['foto_url'] = nuevaFotoUrl;
      }

      await _supabase
          .from('funcionarios')
          .update(updateData)
          .eq('id', funcionarioId);

      if (_cambiarPassword && _passwordController.text.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      final fd = await _supabase
          .from('funcionarios')
          .select()
          .eq('id', funcionarioId)
          .maybeSingle();

      if (fd != null && mounted) {
        authService.updateFuncionarioData(Map<String, dynamic>.from(fd));
      }

      if (!mounted) return;
      setState(() {
        _editando = false;
        _guardando = false;
        _subiendoFoto = false;
        _cambiarPassword = false;
        _nuevaFotoBytes = null;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppConfig.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _subiendoFoto = false;
      });
      _showError('Error al guardar: ${e.toString()}');
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  Future<void> _cerrarSesion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo),
    );
  }

  String _getInitial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'F';
    return clean[0].toUpperCase();
  }

  Widget _buildAvatarHero({
    required bool isMobile,
    required String nombre,
    required String? fotoUrl,
  }) {
    final radius = isMobile ? 34.0 : 40.0;
    final fontSize = isMobile ? 28.0 : 34.0;

    if (_nuevaFotoBytes != null) {
      return GestureDetector(
        onTap: _editando ? _mostrarOpcionesFoto : null,
        child: Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(_nuevaFotoBytes!),
            ),
            if (_editando)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConfig.azulClaro,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return GestureDetector(
        onTap: _editando ? _mostrarOpcionesFoto : null,
        child: Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundImage: NetworkImage(fotoUrl),
              onBackgroundImageError: (_, __) {},
            ),
            if (_editando)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConfig.azulClaro,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _editando ? _mostrarOpcionesFoto : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: Text(
              _getInitial(nombre),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppConfig.azulOscuro,
              ),
            ),
          ),
          if (_editando)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConfig.azulClaro,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add_a_photo_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    final authService = Provider.of<AuthService>(context);
    final fd = authService.funcionarioData;

    final nombre = fd?['nombre']?.toString() ??
        widget.userData['nombre']?.toString() ??
        'Funcionario';
    final correo = fd?['correo']?.toString() ??
        widget.userData['correo']?.toString() ??
        '';
    final cargo = fd?['cargo']?.toString() ??
        widget.userData['cargo']?.toString() ??
        'Funcionario';
    final departamento = fd?['departamento']?.toString() ??
        widget.userData['departamento']?.toString() ??
        'No especificado';
    final fotoUrl = fd?['foto_url']?.toString();

    final userData = {
      'nombre': nombre,
      'correo': correo,
      'cargo': cargo,
      'departamento': departamento,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isMobile
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        actions: [
          if (!_editando)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => setState(() => _editando = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  foregroundColor: Colors.white,
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: (_guardando || _subiendoFoto)
                    ? null
                    : () {
                        setState(() {
                          _editando = false;
                          _cambiarPassword = false;
                          _nuevaFotoBytes = null;
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          _cargarDatos();
                        });
                      },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 4,
        userData: userData,
      ),
      bottomNavigationBar:
          FuncionarioBottomNav.maybe(context, currentIndex: 4),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: isMobile
                  ? _buildMobileLayout(
                      nombre, correo, cargo, departamento, fotoUrl, userData)
                  : _buildWebLayout(
                      nombre, correo, cargo, departamento, fotoUrl, userData),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String nombre, String correo, String cargo,
      String departamento, String? fotoUrl, Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildHero(
          isMobile: true,
          nombre: nombre,
          correo: correo,
          cargo: cargo,
          departamento: departamento,
          fotoUrl: fotoUrl,
        ),
        const SizedBox(height: 18),
        _buildInfoCard(nombre, correo, cargo, departamento),
        const SizedBox(height: 18),
        _buildActivityCard(),
        const SizedBox(height: 18),
        _buildSecurityCard(),
      ],
    );
  }

  Widget _buildWebLayout(String nombre, String correo, String cargo,
      String departamento, String? fotoUrl, Map<String, dynamic> userData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(
                isMobile: false,
                nombre: nombre,
                correo: correo,
                cargo: cargo,
                departamento: departamento,
                fotoUrl: fotoUrl,
              ),
              const SizedBox(height: 20),
              _buildSecurityCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildInfoCard(nombre, correo, cargo, departamento),
              const SizedBox(height: 20),
              _buildActivityCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero({
    required bool isMobile,
    required String nombre,
    required String correo,
    required String cargo,
    required String departamento,
    required String? fotoUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulOscuro.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -6,
            child: Icon(
              Icons.person_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.verified_user_rounded,
                text: 'Perfil institucional',
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarHero(
                      isMobile: isMobile,
                      nombre: nombre,
                      fotoUrl: fotoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 25 : 34,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          correo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: isMobile ? 12.5 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(icon: Icons.work_rounded, text: cargo),
                  _HeroChip(
                    icon: Icons.corporate_fare_rounded,
                    text: departamento,
                  ),
                ],
              ),
              if (_editando) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 7),
                        Text(
                          _nuevaFotoBytes != null
                              ? 'Cambiar foto'
                              : 'Cambiar foto de perfil',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String nombre, String correo, String cargo, String departamento) {
    return _SoftCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeading(
              icon: Icons.badge_rounded,
              title: 'Información del funcionario',
              subtitle: _editando
                  ? 'Modifica tus datos y guarda los cambios.'
                  : 'Toca "Editar" para modificar tu información.',
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _nombreController,
              label: 'Nombre completo *',
              icon: Icons.person_rounded,
              color: AppConfig.azulClaro,
              enabled: _editando,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: TextEditingController(text: correo),
              label: 'Correo electrónico',
              icon: Icons.email_rounded,
              color: AppConfig.rojo,
              enabled: false,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _cargoController,
              label: 'Cargo *',
              icon: Icons.work_rounded,
              color: AppConfig.verde,
              enabled: _editando,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _departamentoController,
              label: 'División / Área *',
              icon: Icons.corporate_fare_rounded,
              color: AppConfig.naranja,
              enabled: _editando,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            if (_editando) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    setState(() => _cambiarPassword = !_cambiarPassword),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cambiarPassword
                        ? AppConfig.azulOscuro.withOpacity(0.06)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _cambiarPassword
                          ? AppConfig.azulOscuro.withOpacity(0.3)
                          : AppConfig.grisMedio,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cambiarPassword
                            ? Icons.lock_rounded
                            : Icons.lock_outline_rounded,
                        color: AppConfig.azulOscuro,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _cambiarPassword
                              ? 'Cambiar contraseña (activo)'
                              : 'Cambiar contraseña',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppConfig.azulOscuro,
                          ),
                        ),
                      ),
                      Icon(
                        _cambiarPassword
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppConfig.azulOscuro,
                      ),
                    ],
                  ),
                ),
              ),
              if (_cambiarPassword) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      (_guardando || _subiendoFoto) ? null : _guardar,
                  icon: (_guardando || _subiendoFoto)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_subiendoFoto
                      ? 'Subiendo foto...'
                      : _guardando
                          ? 'Guardando...'
                          : 'Guardar cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.azulClaro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.timeline_rounded,
            title: 'Resumen de actividad',
            subtitle: 'Basado en tus casos reales en la base de datos.',
          ),
          const SizedBox(height: 18),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            _MiniStatRow(
              label: 'Casos asignados',
              value: '$_totalCasos',
              icon: Icons.assignment_rounded,
              color: AppConfig.azulClaro,
            ),
            const SizedBox(height: 12),
            _MiniStatRow(
              label: 'Casos en revisión',
              value: '$_casosRevision',
              icon: Icons.autorenew_rounded,
              color: AppConfig.naranja,
            ),
            const SizedBox(height: 12),
            _MiniStatRow(
              label: 'Casos resueltos',
              value: '$_casosResueltos',
              icon: Icons.check_circle_rounded,
              color: AppConfig.verde,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.security_rounded,
            title: 'Sesión y seguridad',
            subtitle: 'Control rápido de acceso a tu cuenta.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConfig.verde.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppConfig.verde.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConfig.verde.withOpacity(0.12),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppConfig.verde,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sesión activa',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppConfig.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tu cuenta está autenticada y aprobada.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppConfig.grisOscuro,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.rojo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFF8FAFC)
            : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Widgets compartidos ──────────────────────────────────────────────────────

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulOscuro),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12.5, color: AppConfig.grisOscuro)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppConfig.azulOscuro)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}