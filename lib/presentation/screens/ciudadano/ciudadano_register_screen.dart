import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }

    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telefono: _telefonoController.text.trim(),
      barrio: _barrioController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      // Si quedó logueado directo, ir al home
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
        SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo));
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
              child: Text('¡Registro exitoso!',
                  style: TextStyle(fontWeight: FontWeight.w800)),
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
                  borderRadius: BorderRadius.circular(14)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Registro de Ciudadano'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
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
          if (svc.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creando cuenta...',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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
            child: Icon(Icons.how_to_reg_rounded,
                size: isMobile ? 90 : 130,
                color: Colors.white.withOpacity(0.07)),
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
                    Text('Nuevo ciudadano',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroChip(icon: Icons.lock_rounded, text: 'Datos protegidos'),
                  _HeroChip(icon: Icons.verified_rounded, text: 'Registro gratuito'),
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
          _PanelHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Antes de registrarte',
            subtitle: 'Ten en cuenta estas recomendaciones.',
          ),
          const SizedBox(height: 18),
          _TipItem(
            icon: Icons.shield_rounded,
            text: 'Tus datos personales están protegidos y solo se usarán para gestionar tus reportes.',
          ),
          _TipItem(
            icon: Icons.confirmation_number_rounded,
            text: 'Al hacer un reporte recibirás un código único para consultar su estado.',
          ),
          _TipItem(
            icon: Icons.visibility_off_rounded,
            text: 'Puedes elegir que tu reporte sea anónimo si no quieres compartir tus datos.',
            isLast: true,
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
                  child: const Icon(Icons.assignment_ind_rounded,
                      color: AppConfig.azulOscuro),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datos personales',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppConfig.azulOscuro)),
                      const SizedBox(height: 3),
                      Text('Completa la información para crear tu cuenta.',
                          style: TextStyle(
                              fontSize: 13, color: AppConfig.grisOscuro)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                          borderRadius: BorderRadius.circular(16)),
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
                          borderRadius: BorderRadius.circular(16)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                          borderRadius: BorderRadius.circular(16)),
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
                          borderRadius: BorderRadius.circular(16)),
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
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                  Text(_strengthText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _strengthColor)),
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
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                            height: 1.35),
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
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800),
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
        Text(text,
            style: TextStyle(
                fontSize: 11.5,
                color: isMet ? AppConfig.verde : AppConfig.grisOscuro,
                fontWeight: isMet ? FontWeight.w700 : FontWeight.w400)),
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
          Text(text,
              style: const TextStyle(
                  fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PanelHeading(
      {required this.icon, required this.title, required this.subtitle});

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
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
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
  const _TipItem({required this.icon, required this.text, this.isLast = false});

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
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, height: 1.35, color: AppConfig.grisOscuro)),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 22),
      ],
    );
  }
}