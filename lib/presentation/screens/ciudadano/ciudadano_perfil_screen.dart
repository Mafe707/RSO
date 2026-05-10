import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

class CiudadanoPerfilScreen extends StatefulWidget {
  const CiudadanoPerfilScreen({super.key});

  @override
  State<CiudadanoPerfilScreen> createState() => _CiudadanoPerfilScreenState();
}

class _CiudadanoPerfilScreenState extends State<CiudadanoPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _barrioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _editando = false;
  bool _guardando = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _cambiarPassword = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final d = svc.ciudadanoData;
    if (d == null) return;
    _nombreController.text = d['nombre'] ?? '';
    _apellidoController.text = d['apellido'] ?? '';
    _telefonoController.text = d['telefono'] ?? '';
    _barrioController.text = d['barrio'] ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _barrioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
      final ciudadanoId = svc.ciudadanoData?['id'];
      if (ciudadanoId == null) throw Exception('No se encontró el perfil');

      final supabase = SupabaseConfig.client;

      await supabase.from('ciudadanos').update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        'barrio': _barrioController.text.trim().isEmpty
            ? null
            : _barrioController.text.trim(),
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', ciudadanoId);

      if (_cambiarPassword && _passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      await svc.refreshData();

      if (!mounted) return;
      setState(() {
        _editando = false;
        _guardando = false;
        _cambiarPassword = false;
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
      setState(() => _guardando = false);
      _showError('Error al guardar: ${e.toString()}');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<CiudadanoAuthService>(context);
    final d = svc.ciudadanoData;
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
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
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
                onPressed: _guardando
                    ? null
                    : () {
                        setState(() {
                          _editando = false;
                          _cambiarPassword = false;
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
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 5),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: isMobile ? _buildMobileLayout(d, svc) : _buildWebLayout(d, svc),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic>? d, CiudadanoAuthService svc) {
    return Column(
      children: [
        _buildHero(d, isMobile: true),
        const SizedBox(height: 20),
        _buildFormCard(d),
      ],
    );
  }

  Widget _buildWebLayout(Map<String, dynamic>? d, CiudadanoAuthService svc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _buildHero(d, isMobile: false)),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _buildFormCard(d)),
      ],
    );
  }

  Widget _buildHero(Map<String, dynamic>? d, {required bool isMobile}) {
    final nombre = d?['nombre'] ?? '';
    final apellido = d?['apellido'] ?? '';
    final correo = d?['correo'] ?? '';
    final barrio = d?['barrio'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
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
            bottom: 8,
            child: Icon(
              Icons.account_circle_rounded,
              size: isMobile ? 100 : 132,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Column(
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$nombre $apellido',
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                correo,
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 13.5,
                ),
              ),
              if (barrio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      barrio,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ciudadano registrado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic>? d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppConfig.azulOscuro.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppConfig.azulOscuro,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppConfig.azulOscuro,
                        ),
                      ),
                      Text(
                        _editando
                            ? 'Modifica tus datos y guarda los cambios.'
                            : 'Toca "Editar" para modificar tu información.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppConfig.grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _nombreController,
                    label: 'Nombre *',
                    icon: Icons.person_outline_rounded,
                    enabled: _editando,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _apellidoController,
                    label: 'Apellido *',
                    icon: Icons.person_outline_rounded,
                    enabled: _editando,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: TextEditingController(text: d?['correo'] ?? ''),
              label: 'Correo electrónico',
              icon: Icons.email_rounded,
              enabled: false,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    icon: Icons.phone_rounded,
                    enabled: _editando,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _barrioController,
                    label: 'Barrio',
                    icon: Icons.location_city_rounded,
                    enabled: _editando,
                  ),
                ),
              ],
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
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppConfig.grisMedio),
        ),
      ),
    );
  }
}