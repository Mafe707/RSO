import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_home_screen.dart';

class CiudadanoRegisterScreen extends StatefulWidget {
  const CiudadanoRegisterScreen({super.key});

  @override
  State<CiudadanoRegisterScreen> createState() =>
      _CiudadanoRegisterScreenState();
}

class _CiudadanoRegisterScreenState extends State<CiudadanoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _barrioController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;

  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasNumber = false;

  Uint8List? _fotoBytes;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPassword);
  }

  void _checkPassword() {
    final p = _passwordController.text;
    setState(() {
      _hasMinLength = p.length >= 8;
      _hasUpperCase = p.contains(RegExp(r'[A-Z]'));
      _hasNumber = p.contains(RegExp(r'[0-9]'));
    });
  }

  int get _strength =>
      (_hasMinLength ? 1 : 0) + (_hasUpperCase ? 1 : 0) + (_hasNumber ? 1 : 0);

  Color get _strengthColor {
    if (_strength <= 1) return AppConfig.rojo;
    if (_strength == 2) return AppConfig.naranja;
    return AppConfig.verde;
  }

  String get _strengthText {
    if (_strength <= 1) return 'Débil';
    if (_strength == 2) return 'Media';
    return 'Fuerte';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_checkPassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _barrioController.dispose();
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

      if (cropped == null) return;

      final bytes = await File(cropped.path).readAsBytes();

      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
    } catch (e) {
      _showError('No se pudo seleccionar o ajustar la imagen');
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
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppConfig.azulClaro,
                  ),
                ),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Luego podrás ajustarla'),
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
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppConfig.verde,
                  ),
                ),
                title: const Text(
                  'Galería / Archivos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Elige y ubica la imagen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFoto(ImageSource.gallery);
                },
              ),
              if (_fotoBytes != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConfig.rojo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppConfig.rojo,
                    ),
                  ),
                  title: const Text(
                    'Eliminar foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConfig.rojo,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _fotoBytes = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<({String? url, String? path})> _subirFoto(String emailNorm) async {
    if (_fotoBytes == null) return (url: null, path: null);

    final supabase = SupabaseConfig.client;
    final nombre =
        'ciudadano_${emailNorm.replaceAll('@', '_').replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'ciudadanos/$nombre';

    await supabase.storage.from('avatares').uploadBinary(
          path,
          _fotoBytes!,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    final url = supabase.storage.from('avatares').getPublicUrl(path);
    return (url: url, path: path);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _subiendoFoto = true);

    String? fotoUrl;
    String? fotoPath;

    try {
      final result =
          await _subirFoto(_emailController.text.trim().toLowerCase());
      fotoUrl = result.url;
      fotoPath = result.path;
    } catch (e) {
      debugPrint('Error subiendo foto: $e');
    } finally {
      setState(() => _subiendoFoto = false);
    }

    if (!mounted) return;

    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telefono: _telefonoController.text.trim(),
      barrio: _barrioController.text.trim(),
      fotoUrl: fotoUrl,
      fotoPath: fotoPath,
    );

    if (!mounted) return;

    if (ok) {
      if (svc.isLoggedIn) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CiudadanoHomeScreen()),
          (route) => false,
        );
      } else {
        _showSuccessDialog();
      }
    } else {
      _showError(svc.error ?? 'Error al registrar');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConfig.rojo,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppConfig.verde),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Registro exitoso!',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tu cuenta ha sido creada correctamente.\nYa puedes iniciar sesión.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.azulClaro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Ir al inicio de sesión'),
          ),
        ],
      ),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 820;

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<CiudadanoAuthService>(context);
    final isMobile = _isMobile(context);
    final loading = svc.isLoading || _subiendoFoto;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Registro Ciudadano',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 16,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: isMobile
                    ? _buildMobileLayout()
                    : _buildWebLayout(),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _subiendoFoto
                              ? 'Subiendo foto...'
                              : 'Creando cuenta...',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 18),
        _buildFormCard(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(isMobile: false),
              const SizedBox(height: 22),
              _buildTipsCard(),
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(flex: 6, child: _buildFormCard()),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
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
            bottom: -24,
            child: Icon(
              Icons.how_to_reg_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Nuevo ciudadano',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 22),
              Text(
                'Crea tu cuenta ciudadana',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  'Regístrate para reportar invasiones al espacio público y hacer seguimiento de tus denuncias con un código único.',
                  style: TextStyle(
                    fontSize: isMobile ? 13.5 : 15.5,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.84),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(
                    icon: Icons.lock_rounded,
                    text: 'Datos protegidos',
                  ),
                  _HeroChip(
                    icon: Icons.verified_rounded,
                    text: 'Registro gratuito',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Antes de registrarte',
            subtitle: 'Ten en cuenta estas recomendaciones.',
          ),
          const SizedBox(height: 18),
          const _TipItem(
            icon: Icons.shield_rounded,
            text:
                'Tus datos personales están protegidos y solo se usarán para gestionar tus reportes.',
          ),
          const _TipItem(
            icon: Icons.confirmation_number_rounded,
            text:
                'Al hacer un reporte recibirás un código único para consultar su estado.',
          ),
          const _TipItem(
            icon: Icons.visibility_off_rounded,
            text:
                'Puedes elegir que tu reporte sea anónimo si no quieres compartir tus datos.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFotoSelector() {
    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConfig.azulOscuro.withOpacity(0.08),
                  border: Border.all(
                    color: _fotoBytes != null
                        ? AppConfig.azulClaro
                        : AppConfig.grisMedio,
                    width: _fotoBytes != null ? 2.5 : 1.5,
                  ),
                ),
                child: _fotoBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _fotoBytes!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 42,
                        color: AppConfig.azulOscuro,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConfig.azulClaro,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fotoBytes != null
                ? 'Cambiar o ajustar foto'
                : 'Agregar foto (opcional)',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppConfig.azulClaro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: AppConfig.azulOscuro.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    color: AppConfig.azulOscuro,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos personales',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppConfig.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Completa la información para crear tu cuenta.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(child: _buildFotoSelector()),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _apellidoController,
                    decoration: InputDecoration(
                      labelText: 'Apellido *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico *',
                hintText: 'tu@correo.com',
                prefixIcon: const Icon(Icons.email_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      prefixIcon: const Icon(Icons.phone_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barrioController,
                    decoration: InputDecoration(
                      labelText: 'Barrio (opcional)',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña *',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _strength / 3,
                        backgroundColor: AppConfig.grisMedio,
                        color: _strengthColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _strengthText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                children: [
                  _ReqIndicator('8+ caracteres', _hasMinLength),
                  _ReqIndicator('Mayúscula', _hasUpperCase),
                  _ReqIndicator('Número', _hasNumber),
                ],
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña *',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppConfig.grisMedio),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: AppConfig.verde,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _termsAccepted = !_termsAccepted),
                      child: Text(
                        'Acepto los términos y condiciones y la política de privacidad del sistema',
                        style: TextStyle(
                          color: AppConfig.grisOscuro,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _register,
                icon: const Icon(Icons.how_to_reg_rounded),
                label: const Text('Crear cuenta'),
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
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Ya tengo cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReqIndicator extends StatelessWidget {
  final String text;
  final bool isMet;

  const _ReqIndicator(this.text, this.isMet);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: isMet ? AppConfig.verde : AppConfig.grisOscuro,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: isMet ? AppConfig.verde : AppConfig.grisOscuro,
            fontWeight: isMet ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelHeading({
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _TipItem({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConfig.azulClaro, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 22),
      ],
    );
  }
}