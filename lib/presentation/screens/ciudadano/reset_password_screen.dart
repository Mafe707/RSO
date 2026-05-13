import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Paso 1: correo
  final _emailCtrl = TextEditingController();
  // Paso 2: OTP
  final _otpCtrl = TextEditingController();
  // Paso 3: nueva contraseña
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 1; // 1 = correo, 2 = OTP, 3 = nueva contraseña
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Ingresa tu correo', error: true);
      return;
    }

    setState(() => _loading = true);
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.sendPasswordResetOtp(email);
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      setState(() => _step = 2);
      _snack('Código enviado, revisa tu correo');
    } else {
      _snack(svc.error ?? 'Error al enviar', error: true);
    }
  }

  Future<void> _verificarOtp() async {
    final token = _otpCtrl.text.trim();
    if (token.length < 6) {
      _snack('Ingresa el código de 6 dígitos', error: true);
      return;
    }

    setState(() => _loading = true);
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.verifyOtp(_emailCtrl.text.trim(), token);
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      setState(() => _step = 3);
    } else {
      _snack(svc.error ?? 'Código inválido', error: true);
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passCtrl.text.length < 6) {
      _snack('Mínimo 6 caracteres', error: true);
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Las contraseñas no coinciden', error: true);
      return;
    }

    setState(() => _loading = true);
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    final ok = await svc.updatePassword(_passCtrl.text);
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      svc.setPasswordRecovery(false);
      await svc.logout();
      _snack('Contraseña actualizada. Inicia sesión.');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
        (route) => false,
      );
    } else {
      _snack(svc.error ?? 'Error al actualizar', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppConfig.rojo : AppConfig.azulClaro,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _step == 1
                        ? _buildPaso1(key: const ValueKey(1))
                        : _step == 2
                            ? _buildPaso2(key: const ValueKey(2))
                            : _buildPaso3(key: const ValueKey(3)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _icono(Icons.email_rounded),
        const SizedBox(height: 18),
        const Text('Recuperar contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
        const SizedBox(height: 6),
        Text('Te enviaremos un código a tu correo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro)),
        const SizedBox(height: 28),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco('Correo electrónico', Icons.email_rounded),
        ),
        const SizedBox(height: 24),
        _boton('Enviar código', _loading ? null : _enviarOtp),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
            (r) => false,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Volver al inicio de sesión'),
        ),
      ],
    );
  }

  Widget _buildPaso2({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _icono(Icons.pin_rounded),
        const SizedBox(height: 18),
        const Text('Ingresa el código',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
        const SizedBox(height: 6),
        Text('Revisa tu correo ${_emailCtrl.text} y pega el código de 6 dígitos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro)),
        const SizedBox(height: 28),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
          decoration: _inputDeco('Código OTP', Icons.pin_rounded),
        ),
        const SizedBox(height: 24),
        _boton('Verificar código', _loading ? null : _verificarOtp),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _step = 1),
          child: const Text('Reenviar código'),
        ),
      ],
    );
  }

  Widget _buildPaso3({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _icono(Icons.lock_reset_rounded),
        const SizedBox(height: 18),
        const Text('Nueva contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
        const SizedBox(height: 6),
        Text('Ingresa y confirma tu nueva contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro)),
        const SizedBox(height: 28),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure1,
          decoration: _inputDeco('Nueva contraseña', Icons.lock_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure2,
          decoration: _inputDeco('Confirmar contraseña', Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _boton('Cambiar contraseña', _loading ? null : _cambiarPassword),
      ],
    );
  }

  Widget _icono(IconData icon) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: AppConfig.azulClaro.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 42, color: AppConfig.azulClaro),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _boton(String texto, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.azulClaro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        child: _loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(texto),
      ),
    );
  }
}