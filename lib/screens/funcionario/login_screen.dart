import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
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

    // Validar formato de email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Ingrese un correo electrónico válido');
      return;
    }

    // Validar que sea correo institucional
    if (!email.endsWith('@alcaldia.gov.co')) {
      _showError('Debe usar su correo institucional (@alcaldia.gov.co)');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    final success = await authService.login(email, password);
    
    if (success && mounted) {
      _showSuccess('Login exitoso');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FuncionarioHomeScreen()),
      );
    } else if (mounted) {
      _showError(authService.error ?? 'Credenciales incorrectas');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppConfig.rojo),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppConfig.verde),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConfig.azulClaro.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 50, color: AppConfig.azulClaro),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Inicio de Sesión',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Panel de Funcionario',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      // Campo email
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          helperText: 'Debe ser @alcaldia.gov.co',
                          helperStyle: TextStyle(fontSize: 11),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo contraseña
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 8),
                      
                      // Olvidó contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showError('Contacte al administrador para recuperar su contraseña'),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Botón login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authService.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.azulClaro,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: authService.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Link a registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FuncionarioRegisterScreen()),
                              );
                            },
                            child: const Text('Regístrate aquí'),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Volver
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('← Volver a selección de roles'),
                      ),
                      
                      // Datos de prueba
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.grisClaro,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Datos de prueba:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Email: funcionario@alcaldia.gov.co',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              'Contraseña: 123456',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}