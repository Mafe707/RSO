import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class FuncionarioRegisterScreen extends StatefulWidget {
  const FuncionarioRegisterScreen({super.key});

  @override
  State<FuncionarioRegisterScreen> createState() => _FuncionarioRegisterScreenState();
}

class _FuncionarioRegisterScreenState extends State<FuncionarioRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cargoController = TextEditingController();
  
  String? _departamentoSeleccionado;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final List<String> _departamentos = [
    'Espacio Público',
    'Seguridad Ciudadana',
    'Planeación Urbana',
    'Movilidad',
    'Medio Ambiente',
    'Control Urbano',
    'Otros',
  ];
  
  // Validación de contraseña en tiempo real
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasNumber = false;
  
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cargoController.dispose();
    super.dispose();
  }
  
  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }
  
  int _getPasswordStrength() {
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasUpperCase) strength++;
    if (_hasNumber) strength++;
    return strength;
  }
  
  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrength();
    if (strength <= 1) return AppConfig.rojo;
    if (strength <= 2) return AppConfig.naranja;
    return AppConfig.verde;
  }
  
  String _getPasswordStrengthText() {
    final strength = _getPasswordStrength();
    if (strength <= 1) return 'Débil';
    if (strength <= 2) return 'Media';
    return 'Fuerte';
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_termsAccepted) {
      _showError('Debe aceptar los términos y condiciones');
      return;
    }
    
    final email = _emailController.text.trim().toLowerCase();
    
    // Validar correo institucional
    if (!email.endsWith('@alcaldia.gov.co')) {
      _showError('Debe usar su correo institucional (@alcaldia.gov.co)');
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final success = await authService.register(
      nombre: '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
      email: email,
      password: _passwordController.text,
      cargo: _cargoController.text.trim(),
      departamento: _departamentoSeleccionado!,
    );
    
    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      _showError(authService.error ?? 'Error al registrar');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppConfig.rojo),
    );
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppConfig.verde),
            SizedBox(width: 10),
            Text('¡Registro exitoso!'),
          ],
        ),
        content: const Text(
          'Su cuenta ha sido creada exitosamente. Será redirigido al inicio de sesión.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.azulClaro),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Funcionario'),
        backgroundColor: AppConfig.azulOscuro,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConfig.azulClaro.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add, size: 50, color: AppConfig.azulClaro),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Complete el formulario para crear su cuenta',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: 'Ingrese su nombre',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Apellido
                  TextFormField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      hintText: 'Ingrese su apellido',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'El apellido es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Correo
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      hintText: 'funcionario@alcaldia.gov.co',
                      helperText: 'Solo se permiten correos @alcaldia.gov.co',
                      helperStyle: TextStyle(fontSize: 11),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'El correo es requerido';
                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      if (!emailRegex.hasMatch(value!)) return 'Ingrese un correo válido';
                      if (!value.toLowerCase().endsWith('@alcaldia.gov.co')) {
                        return 'Debe usar @alcaldia.gov.co';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Mínimo 8 caracteres, una mayúscula y un número',
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'La contraseña es requerida';
                      if (value!.length < 8) return 'Mínimo 8 caracteres';
                      if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe tener una letra mayúscula';
                      if (!value.contains(RegExp(r'[0-9]'))) return 'Debe tener un número';
                      return null;
                    },
                  ),
                  
                  // Indicador de fortaleza
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _getPasswordStrength() / 3,
                            backgroundColor: AppConfig.grisClaro,
                            color: _getPasswordStrengthColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getPasswordStrengthText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPasswordStrengthColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildRequirementIndicator('8+ caracteres', _hasMinLength),
                        _buildRequirementIndicator('Mayúscula', _hasUpperCase),
                        _buildRequirementIndicator('Número', _hasNumber),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Cargo
                  TextFormField(
                    controller: _cargoController,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Inspector de Espacio Público',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'El cargo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Departamento
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConfig.grisMedio),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _departamentoSeleccionado,
                        hint: const Text('Seleccione un departamento'),
                        isExpanded: true,
                        items: _departamentos.map((depto) {
                          return DropdownMenuItem(value: depto, child: Text(depto));
                        }).toList(),
                        onChanged: (value) => setState(() => _departamentoSeleccionado = value),
                        validator: (value) => value == null ? 'Seleccione un departamento' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Términos
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                        activeColor: AppConfig.verde,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppConfig.grisOscuro, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'términos y condiciones',
                                  style: const TextStyle(color: AppConfig.azulClaro),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'política de privacidad',
                                  style: const TextStyle(color: AppConfig.azulClaro),
                                ),
                                const TextSpan(text: ' del sistema'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón registrar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authService.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.verde,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('REGISTRARSE', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Link a login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Inicia sesión aquí'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (authService.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creando cuenta...'),
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
  
  Widget _buildRequirementIndicator(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle,
          size: 12,
          color: isMet ? AppConfig.verde : AppConfig.grisOscuro,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isMet ? AppConfig.verde : AppConfig.grisOscuro,
          ),
        ),
      ],
    );
  }
}