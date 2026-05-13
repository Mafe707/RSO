import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_home_screen.dart';
import 'ciudadano_register_screen.dart';
import 'reset_password_screen.dart';
import '../rol_selection_screen.dart';

class CiudadanoLoginScreen extends StatefulWidget {
  const CiudadanoLoginScreen({super.key});

  @override
  State<CiudadanoLoginScreen> createState() => _CiudadanoLoginScreenState();
}

class _CiudadanoLoginScreenState extends State<CiudadanoLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveSession();
    });
  }

  void _checkActiveSession() {
    if (!mounted || _redirecting) return;

    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);

    if (svc.isLoggedIn) {
      _redirecting = true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
      if (!svc.isLoading && svc.isLoggedIn) {
        _checkActiveSession();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showError('El correo es requerido');
      return;
    }
    if (password.isEmpty) {
      _showError('La contraseña es requerida');
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Ingresa un correo válido');
      return;
    }

    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.login(email, password);

    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoHomeScreen()),
        (route) => false,
      );
    } else {
      _showError(svc.error ?? 'Credenciales incorrectas');
    }
  }

  void _mostrarDialogoReset(BuildContext context, CiudadanoAuthService svc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<CiudadanoAuthService>(context);
    final isMobile = _isMobile(context);

    if ((svc.isLoading && !svc.isLoggedIn) || _redirecting) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(
          child: CircularProgressIndicator(
            color: AppConfig.azulClaro,
          ),
        ),
      );
    }

    if (svc.isLoggedIn) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(
          child: CircularProgressIndicator(
            color: AppConfig.azulClaro,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 24 : 36,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: isMobile ? _buildMobileLayout(svc) : _buildWebLayout(svc),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(CiudadanoAuthService svc) {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 24),
        _buildLoginCard(svc),
      ],
    );
  }

  Widget _buildWebLayout(CiudadanoAuthService svc) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildHero(isMobile: false)),
        const SizedBox(width: 42),
        Expanded(flex: 5, child: _buildLoginCard(svc)),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 22 : 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Icon(
            Icons.person_pin_rounded,
            size: isMobile ? 64 : 82,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 20 : 30),
        Text(
          'Portal Ciudadano',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 30 : 46,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Inicia sesión para reportar invasiones al espacio público, consultar el estado de tus denuncias y hacer seguimiento.',
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: isMobile ? 14 : 17,
              height: 1.45,
              color: Colors.white.withOpacity(0.84),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroChip(icon: Icons.shield_rounded, text: 'Reporte seguro'),
            _HeroChip(
              icon: Icons.confirmation_number_rounded,
              text: 'Código de seguimiento',
            ),
            _HeroChip(
              icon: Icons.access_time_rounded,
              text: 'Disponible 24/7',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard(CiudadanoAuthService svc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppConfig.azulClaro.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: AppConfig.azulClaro,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppConfig.azulOscuro,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa con tu correo y contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            enabled: !svc.isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tu@correo.com',
              prefixIcon: const Icon(Icons.email_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            enabled: !svc.isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: svc.isLoading
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) {
              if (!svc.isLoading) _login();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: svc.isLoading ? null : _login,
              icon: svc.isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                svc.isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
              ),
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: svc.isLoading
                ? null
                : () => _mostrarDialogoReset(context, svc),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta?',
                style: TextStyle(color: AppConfig.grisOscuro),
              ),
              TextButton(
                onPressed: svc.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CiudadanoRegisterScreen(),
                          ),
                        ),
                child: const Text('Regístrate aquí'),
              ),
            ],
          ),
          const Divider(height: 28),
          TextButton.icon(
            onPressed: svc.isLoading
                ? null
                : () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const RolSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver a selección de roles'),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}