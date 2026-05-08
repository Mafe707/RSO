import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/admin_auth_service.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Complete todos los campos');
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailRegex.hasMatch(email)) {
      _showError('Ingrese un correo electrónico válido');
      return;
    }

    final adminAuthService = Provider.of<AdminAuthService>(
      context,
      listen: false,
    );

    final success = await adminAuthService.loginAdmin(email, password);

    if (!mounted) return;

    if (!success) {
      _showError(adminAuthService.error ?? 'Credenciales incorrectas');
      return;
    }

    final adminData = adminAuthService.adminData;

    if (adminData == null) {
      await adminAuthService.logoutAdmin();

      if (!mounted) return;

      _showError('No se encontraron datos del administrador');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(
          adminData: adminData,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminAuthService = Provider.of<AdminAuthService>(context);
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
            colors: [
              AppConfig.azulOscuro,
              AppConfig.azulClaro,
            ],
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
                    ? Column(
                        children: [
                          _buildHero(isMobile: true),
                          const SizedBox(height: 24),
                          _buildLoginCard(adminAuthService),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildHero(isMobile: false),
                          ),
                          const SizedBox(width: 42),
                          Expanded(
                            flex: 5,
                            child: _buildLoginCard(adminAuthService),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
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
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          child: Icon(
            Icons.admin_panel_settings_rounded,
            size: isMobile ? 68 : 86,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 20 : 30),
        Text(
          'Supervisor Administrativo',
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
            'Aprueba registros de funcionarios y valida el cierre de reportes institucionales.',
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
              icon: Icons.security_rounded,
              text: 'Acceso seguro',
            ),
            _HeroChip(
              icon: Icons.manage_accounts_rounded,
              text: 'Gestión completa',
            ),
            _HeroChip(
              icon: Icons.analytics_rounded,
              text: 'Panel operativo',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard(AdminAuthService adminAuthService) {
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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppConfig.rojo.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 44,
              color: AppConfig.rojo,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Administrador',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppConfig.azulOscuro,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tus credenciales de supervisor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppConfig.grisOscuro,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            enabled: !adminAuthService.isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'admin@alcaldia.gov.co',
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
            enabled: !adminAuthService.isLoading,
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
                onPressed: adminAuthService.isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) {
              if (!adminAuthService.isLoading) {
                _login();
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: adminAuthService.isLoading ? null : _login,
              icon: adminAuthService.isLoading
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
                adminAuthService.isLoading
                    ? 'Iniciando sesión...'
                    : 'Iniciar sesión',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.rojo,
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
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: adminAuthService.isLoading
                ? null
                : () => Navigator.pop(context),
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

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
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