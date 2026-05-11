import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';

class FuncionarioRegisterScreen extends StatefulWidget {
  const FuncionarioRegisterScreen({super.key});

  @override
  State<FuncionarioRegisterScreen> createState() =>
      _FuncionarioRegisterScreenState();
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
    'Gestión Ambiental',
    'Otros',
  ];

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
    _passwordController.removeListener(_checkPasswordStrength);
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

    if (!email.endsWith('@alcaldia.gov.co')) {
      _showError('Debe usar su correo institucional (@alcaldia.gov.co)');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.register(
      nombre:
          '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
      email: email,
      password: _passwordController.text,
      cargo: _cargoController.text.trim(),
      departamento: _departamentoSeleccionado!,
    );

    if (success && mounted) {
      _showPendingDialog();
    } else if (mounted) {
      _showError(authService.error ?? 'Error al registrar');
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
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppConfig.naranja),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Solicitud enviada',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: const Text(
            'Tu solicitud de registro ha sido enviada correctamente.\n\n'
            'Un administrador revisará tu cuenta y recibirás una notificación '
            'a tu correo institucional cuando sea aprobada.\n\n'
            'Una vez aprobada, podrás iniciar sesión normalmente.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulClaro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 820;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Registro de Funcionario'),
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
                child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
              ),
            ),
          ),
          if (authService.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: _LoadingCard()),
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
        _buildRegisterCard(),
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
        Expanded(flex: 6, child: _buildRegisterCard()),
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
              Icons.person_add_alt_1_rounded,
              size: isMobile ? 100 : 145,
              color: Colors.white.withOpacity(0.08),
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
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Cuenta institucional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Crea tu cuenta de funcionario',
                style: TextStyle(
                  fontSize: isMobile ? 27 : 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Regístrate con tu correo institucional para acceder al panel de gestión de reportes.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(icon: Icons.email_rounded, text: '@alcaldia.gov.co'),
                  _HeroChip(icon: Icons.lock_rounded, text: 'Contraseña segura'),
                  _HeroChip(icon: Icons.badge_rounded, text: 'Datos laborales'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    final authService = Provider.of<AuthService>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const _FormHeader(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 680;

                if (!twoColumns) {
                  return Column(children: _buildMobileFields());
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _nombreField()),
                        const SizedBox(width: 14),
                        Expanded(child: _apellidoField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _emailField(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _passwordField()),
                        const SizedBox(width: 14),
                        Expanded(child: _confirmPasswordField()),
                      ],
                    ),
                    _passwordStrength(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _cargoField()),
                        const SizedBox(width: 14),
                        Expanded(child: _departamentoField()),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _termsWidget(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: authService.isLoading ? null : _register,
                icon: authService.isLoading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  authService.isLoading ? 'Creando cuenta...' : 'Registrarse',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.verde,
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
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('¿Ya tienes cuenta?',
                    style: TextStyle(color: AppConfig.grisOscuro)),
                TextButton(
                  onPressed: authService.isLoading
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Inicia sesión aquí'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMobileFields() {
    return [
      _nombreField(),
      const SizedBox(height: 16),
      _apellidoField(),
      const SizedBox(height: 16),
      _emailField(),
      const SizedBox(height: 16),
      _passwordField(),
      _passwordStrength(),
      const SizedBox(height: 16),
      _confirmPasswordField(),
      const SizedBox(height: 16),
      _cargoField(),
      const SizedBox(height: 16),
      _departamentoField(),
    ];
  }

  Widget _nombreField() {
    return TextFormField(
      controller: _nombreController,
      decoration: _inputDecoration(
          label: 'Nombre',
          hint: 'Ingrese su nombre',
          icon: Icons.person_rounded),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
        return null;
      },
    );
  }

  Widget _apellidoField() {
    return TextFormField(
      controller: _apellidoController,
      decoration: _inputDecoration(
          label: 'Apellido',
          hint: 'Ingrese su apellido',
          icon: Icons.person_outline_rounded),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El apellido es requerido';
        }
        return null;
      },
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _inputDecoration(
        label: 'Correo institucional',
        hint: 'funcionario@alcaldia.gov.co',
        icon: Icons.email_rounded,
        helperText: 'Solo se permiten correos @alcaldia.gov.co',
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'El correo es requerido';
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        if (!emailRegex.hasMatch(value)) return 'Ingrese un correo válido';
        if (!value.toLowerCase().endsWith('@alcaldia.gov.co')) {
          return 'Debe usar @alcaldia.gov.co';
        }
        return null;
      },
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _inputDecoration(
        label: 'Contraseña',
        hint: 'Mínimo 8 caracteres',
        icon: Icons.lock_rounded,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'La contraseña es requerida';
        if (value.length < 8) return 'Mínimo 8 caracteres';
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Debe tener una letra mayúscula';
        }
        if (!value.contains(RegExp(r'[0-9]'))) return 'Debe tener un número';
        return null;
      },
    );
  }

  Widget _confirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: _inputDecoration(
        label: 'Confirmar contraseña',
        hint: 'Repita su contraseña',
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
      ),
      obscureText: _obscureConfirmPassword,
      validator: (value) {
        if (value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _cargoField() {
    return TextFormField(
      controller: _cargoController,
      decoration: _inputDecoration(
        label: 'Cargo',
        hint: 'Ej: Inspector de Espacio Público',
        icon: Icons.business_center_rounded,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'El cargo es requerido';
        return null;
      },
    );
  }

  Widget _departamentoField() {
    return DropdownButtonFormField<String>(
      value: _departamentoSeleccionado,
      hint: const Text('Seleccione una división'),
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'División / Área',
        hint: 'Seleccione una división',
        icon: Icons.corporate_fare_rounded,
      ),
      items: _departamentos
          .map((depto) =>
              DropdownMenuItem<String>(value: depto, child: Text(depto)))
          .toList(),
      onChanged: (value) => setState(() => _departamentoSeleccionado = value),
      validator: (value) {
        if (value == null) return 'Seleccione una división / área';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      helperStyle: const TextStyle(fontSize: 11),
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _passwordStrength() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _getPasswordStrength() / 3,
                  backgroundColor: AppConfig.grisClaro,
                  color: _getPasswordStrengthColor(),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getPasswordStrengthText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getPasswordStrengthColor(),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildRequirementIndicator('8+ caracteres', _hasMinLength),
              _buildRequirementIndicator('Mayúscula', _hasUpperCase),
              _buildRequirementIndicator('Número', _hasNumber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _termsWidget() {
    return Container(
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
            onChanged: (value) =>
                setState(() => _termsAccepted = value ?? false),
            activeColor: AppConfig.verde,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _termsAccepted = !_termsAccepted),
              child: const Text(
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
          _TipItem(
            icon: Icons.hourglass_top_rounded,
            text:
                'Tu cuenta quedará pendiente hasta que el administrador la apruebe.',
          ),
          _TipItem(
            icon: Icons.email_outlined,
            text:
                'Recibirás una notificación a tu correo cuando seas aprobado.',
          ),
          _TipItem(
            icon: Icons.lock_outline_rounded,
            text:
                'La contraseña debe tener mínimo 8 caracteres, una mayúscula y un número.',
            isLast: true,
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

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
                'Datos del funcionario',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Completa la información para crear tu cuenta.',
                style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      ],
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Creando cuenta...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}