import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';

class MiPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MiPerfilScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  Future<void> _cerrarSesion() async {
    final authService = Provider.of<AuthService>(
      context,
      listen: false,
    );

    await authService.logout();

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  String _getInitial(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return 'F';

    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    final nombre = widget.userData['nombre']?.toString() ?? 'Funcionario';
    final correo = widget.userData['correo']?.toString() ?? '';
    final cargo = widget.userData['cargo']?.toString() ?? 'Funcionario';
    final departamento =
        widget.userData['departamento']?.toString() ?? 'No especificado';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        centerTitle: isMobile,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 4,
        userData: widget.userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
        context,
        currentIndex: 4,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: isMobile
                  ? _buildMobileLayout(
                      nombre: nombre,
                      correo: correo,
                      cargo: cargo,
                      departamento: departamento,
                    )
                  : _buildWebLayout(
                      nombre: nombre,
                      correo: correo,
                      cargo: cargo,
                      departamento: departamento,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout({
    required String nombre,
    required String correo,
    required String cargo,
    required String departamento,
  }) {
    return Column(
      children: [
        _buildHero(
          isMobile: true,
          nombre: nombre,
          correo: correo,
          cargo: cargo,
          departamento: departamento,
        ),
        const SizedBox(height: 18),
        _buildInfoCard(
          nombre: nombre,
          correo: correo,
          cargo: cargo,
          departamento: departamento,
        ),
        const SizedBox(height: 18),
        _buildActivityCard(),
        const SizedBox(height: 18),
        _buildSecurityCard(),
      ],
    );
  }

  Widget _buildWebLayout({
    required String nombre,
    required String correo,
    required String cargo,
    required String departamento,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(
                isMobile: false,
                nombre: nombre,
                correo: correo,
                cargo: cargo,
                departamento: departamento,
              ),
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
              _buildInfoCard(
                nombre: nombre,
                correo: correo,
                cargo: cargo,
                departamento: departamento,
              ),
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
    required String correo,
    required String cargo,
    required String departamento,
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
              const _HeroBadge(
                icon: Icons.verified_user_rounded,
                text: 'Perfil institucional',
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
                          nombre,
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
                  _HeroChip(
                    icon: Icons.work_rounded,
                    text: cargo,
                  ),
                  _HeroChip(
                    icon: Icons.apartment_rounded,
                    text: departamento,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String nombre,
    required String correo,
    required String cargo,
    required String departamento,
  }) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.badge_rounded,
            title: 'Información del funcionario',
            subtitle: 'Datos asociados a tu cuenta institucional.',
          ),
          const SizedBox(height: 20),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Nombre completo',
            value: nombre,
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.email_rounded,
            label: 'Correo electrónico',
            value: correo.isEmpty ? 'No disponible' : correo,
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.work_rounded,
            label: 'Cargo',
            value: cargo,
            color: AppConfig.verde,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.apartment_rounded,
            label: 'Departamento',
            value: departamento,
            color: AppConfig.naranja,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardHeading(
            icon: Icons.timeline_rounded,
            title: 'Resumen de actividad',
            subtitle: 'Información visual de tu gestión reciente.',
          ),
          SizedBox(height: 18),
          _MiniStatRow(
            label: 'Casos asignados',
            value: '12',
            icon: Icons.assignment_rounded,
            color: AppConfig.azulClaro,
          ),
          SizedBox(height: 12),
          _MiniStatRow(
            label: 'Casos en revisión',
            value: '4',
            icon: Icons.autorenew_rounded,
            color: AppConfig.naranja,
          ),
          SizedBox(height: 12),
          _MiniStatRow(
            label: 'Casos resueltos',
            value: '3',
            icon: Icons.check_circle_rounded,
            color: AppConfig.verde,
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
              border: Border.all(
                color: AppConfig.verde.withOpacity(0.18),
              ),
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
                        'Tu cuenta está autenticada correctamente.',
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
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppConfig.grisOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppConfig.azulOscuro,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({
    required this.child,
  });

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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
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

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
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