import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';

import 'funcionario_home_screen.dart';
import 'register_screen.dart';

class FuncionarioLoginScreen extends StatefulWidget {
  const FuncionarioLoginScreen({super.key});

  @override
  State<FuncionarioLoginScreen> createState() => _FuncionarioLoginScreenState();
}

class _FuncionarioLoginScreenState extends State<FuncionarioLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showError('El correo electrónico es requerido');
      return;
    }
    if (password.isEmpty) {
      _showError('La contraseña es requerida');
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Ingrese un correo electrónico válido');
      return;
    }
    if (!email.endsWith('@alcaldia.gov.co')) {
      _showError('Debe usar su correo institucional (@alcaldia.gov.co)');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FuncionarioHomeScreen()),
      );
    } else {
      final error = authService.error ?? '';
      if (error == '__pendiente__') {
        _showPendingDialog();
      } else {
        _showError(error.isNotEmpty ? error : 'Credenciales incorrectas');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppConfig.rojo),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppConfig.naranja),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cuenta pendiente',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: const Text(
            'Tu cuenta aún no ha sido aprobada por el administrador.\n\n'
            'Recibirás una notificación a tu correo institucional cuando tu acceso sea habilitado.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulClaro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isMobile = _isMobile(context);

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
                child: isMobile
                    ? _buildMobileLayout(authService)
                    : _buildWebLayout(authService),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthService authService) {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 24),
        _buildLoginCard(authService),
      ],
    );
  }

  Widget _buildWebLayout(AuthService authService) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildHero(isMobile: false)),
        const SizedBox(width: 42),
        Expanded(flex: 5, child: _buildLoginCard(authService)),
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
          child: Icon(Icons.badge_rounded,
              size: isMobile ? 64 : 82, color: Colors.white),
        ),
        SizedBox(height: isMobile ? 20 : 30),
        Text(
          'Panel de Funcionario',
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
            'Accede con tu correo institucional para gestionar reportes, revisar casos asignados y hacer seguimiento.',
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
            _HeroChip(
                icon: Icons.verified_user_rounded,
                text: 'Acceso institucional'),
            _HeroChip(
                icon: Icons.assignment_rounded, text: 'Gestión de casos'),
            _HeroChip(icon: Icons.security_rounded, text: 'Sesión segura'),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthService authService) {
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
            child: const Icon(Icons.person_rounded,
                size: 42, color: AppConfig.azulClaro),
          ),
          const SizedBox(height: 18),
          const Text(
            'Inicio de sesión',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppConfig.azulOscuro,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tus credenciales institucionales',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            enabled: !authService.isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo institucional',
              hintText: 'funcionario@alcaldia.gov.co',
              helperText: 'Debe ser @alcaldia.gov.co',
              helperStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(Icons.email_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            enabled: !authService.isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: authService.isLoading
                    ? null
                    : () =>
                        setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onSubmitted: (_) {
              if (!authService.isLoading) _login();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: authService.isLoading
                  ? null
                  : () => _showError(
                      'Contacte al administrador para recuperar su contraseña'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: authService.isLoading ? null : _login,
              icon: authService.isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(authService.isLoading
                  ? 'Iniciando sesión...'
                  : 'Iniciar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulClaro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('¿No tienes cuenta?',
                  style: TextStyle(color: AppConfig.grisOscuro)),
              TextButton(
                onPressed: authService.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FuncionarioRegisterScreen()),
                        ),
                child: const Text('Regístrate aquí'),
              ),
            ],
          ),
          const Divider(height: 28),
          TextButton.icon(
            onPressed:
                authService.isLoading ? null : () => Navigator.pop(context),
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
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}