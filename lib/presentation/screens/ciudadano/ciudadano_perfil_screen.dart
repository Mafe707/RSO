import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';
import 'ciudadano_login_screen.dart';

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

  int _totalReportes = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarStats();
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

  Future<void> _cargarStats() async {
    try {
      final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
      final ciudadanoId = svc.ciudadanoData?['id'];
      if (ciudadanoId == null) return;

      final supabase = SupabaseConfig.client;
      final response = await supabase
          .from('denuncias')
          .select('id')
          .eq('ciudadano_id', ciudadanoId);

      setState(() {
        _totalReportes = (response as List).length;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
    }
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

  Future<void> _cerrarSesion() async {
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    await svc.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
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

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  String _getInitial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'C';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<CiudadanoAuthService>(context);
    final d = svc.ciudadanoData;
    final isMobile = _isMobile(context);

    final nombre = d?['nombre']?.toString() ?? 'Ciudadano';
    final apellido = d?['apellido']?.toString() ?? '';
    final correo = d?['correo']?.toString() ?? '';
    final telefono = d?['telefono']?.toString() ?? '';
    final barrio = d?['barrio']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        centerTitle: false,
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
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 5),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 5),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: isMobile
                  ? _buildMobileLayout(nombre, apellido, correo, telefono, barrio, d)
                  : _buildWebLayout(nombre, apellido, correo, telefono, barrio, d),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String nombre, String apellido, String correo,
      String telefono, String barrio, Map<String, dynamic>? d) {
    return Column(
      children: [
        _buildHero(isMobile: true, nombre: nombre, apellido: apellido, correo: correo, barrio: barrio),
        const SizedBox(height: 18),
        _buildInfoCard(nombre, apellido, correo, telefono, barrio, d),
        const SizedBox(height: 18),
        _buildActivityCard(),
        const SizedBox(height: 18),
        _buildSecurityCard(),
      ],
    );
  }

  Widget _buildWebLayout(String nombre, String apellido, String correo,
      String telefono, String barrio, Map<String, dynamic>? d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(isMobile: false, nombre: nombre, apellido: apellido, correo: correo, barrio: barrio),
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
              _buildInfoCard(nombre, apellido, correo, telefono, barrio, d),
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
    required String apellido,
    required String correo,
    required String barrio,
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
            bottom: -22,
            child: Icon(
              Icons.person_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(
                icon: Icons.verified_user_rounded,
                text: 'Ciudadano registrado',
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 34 : 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitial(nombre),
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 34,
                        fontWeight: FontWeight.w900,
                        color: AppConfig.azulOscuro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nombre $apellido',
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
                  const _HeroChip(icon: Icons.person_pin_rounded, text: 'Portal Ciudadano'),
                  if (barrio.isNotEmpty)
                    _HeroChip(icon: Icons.location_city_rounded, text: barrio),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String nombre, String apellido, String correo,
      String telefono, String barrio, Map<String, dynamic>? d) {
    return _SoftCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeading(
              icon: Icons.manage_accounts_rounded,
              title: 'Información personal',
              subtitle: _editando
                  ? 'Modifica tus datos y guarda los cambios.'
                  : 'Toca "Editar" para modificar tu información.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _nombreController,
                    label: 'Nombre *',
                    icon: Icons.person_rounded,
                    color: AppConfig.azulClaro,
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
                    icon: Icons.person_rounded,
                    color: AppConfig.azulClaro,
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
              color: AppConfig.rojo,
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
                    color: AppConfig.verde,
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
                    color: AppConfig.naranja,
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

  Widget _buildActivityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.timeline_rounded,
            title: 'Resumen de actividad',
            subtitle: 'Tus reportes registrados en el sistema.',
          ),
          const SizedBox(height: 18),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else
            _MiniStatRow(
              label: 'Reportes enviados',
              value: '$_totalReportes',
              icon: Icons.assignment_rounded,
              color: AppConfig.azulClaro,
            ),
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
              border: Border.all(color: AppConfig.verde.withOpacity(0.18)),
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
                        'Tu sesión está activa.',
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
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2F6),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppConfig.azulOscuro,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
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
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
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