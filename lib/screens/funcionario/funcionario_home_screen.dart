import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';

import 'funcionario_drawer.dart';
import 'funcionario_bottom_nav.dart';
import 'mis_casos_screen.dart';
import 'nuevos_reportes_screen.dart';
import 'mapa_casos_screen.dart';
import 'mi_perfil_screen.dart';

class FuncionarioHomeScreen extends StatefulWidget {
  const FuncionarioHomeScreen({super.key});

  @override
  State<FuncionarioHomeScreen> createState() => _FuncionarioHomeScreenState();
}

class _FuncionarioHomeScreenState extends State<FuncionarioHomeScreen> {
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  Map<String, dynamic> _buildUserData(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return {
      'nombre': user?.userMetadata?['nombre'] ?? 'Funcionario',
      'correo': user?.email ?? '',
      'cargo': user?.userMetadata?['cargo'] ?? '',
      'departamento': user?.userMetadata?['departamento'] ?? '',
    };
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

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final userData = _buildUserData(context);
    final nombre = userData['nombre']?.toString() ?? 'Funcionario';
    final correo = userData['correo']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Panel Funcionario',
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
        currentIndex: 0,
        userData: userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
        context,
        currentIndex: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(
                    isMobile: isMobile,
                    nombre: nombre,
                    correo: correo,
                    userData: userData,
                  ),
                  SizedBox(height: isMobile ? 22 : 28),
                  const _SectionHeader(
                    title: 'Resumen operativo',
                    subtitle: 'Vista rápida de tu actividad institucional.',
                  ),
                  const SizedBox(height: 16),
                  _buildStats(isMobile),
                  SizedBox(height: isMobile ? 24 : 30),
                  const _SectionHeader(
                    title: 'Accesos rápidos',
                    subtitle: 'Continúa con tus tareas de atención.',
                  ),
                  const SizedBox(height: 16),
                  isMobile ? _buildMobileActions(userData) : _buildWebActions(userData),
                  SizedBox(height: isMobile ? 24 : 30),
                  _buildActivityCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero({
    required bool isMobile,
    required String nombre,
    required String correo,
    required Map<String, dynamic> userData,
  }) {
    final cargo = userData['cargo']?.toString() ?? '';
    final departamento = userData['departamento']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
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
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              Icons.badge_rounded,
              size: isMobile ? 105 : 150,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.verified_user_rounded,
                text: 'Sesión funcionario',
              ),
              const SizedBox(height: 18),
              Text(
                'Hola, $nombre',
                style: TextStyle(
                  fontSize: isMobile ? 27 : 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                correo,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
              if (cargo.isNotEmpty || departamento.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (cargo.isNotEmpty)
                      _HeroChip(
                        icon: Icons.work_rounded,
                        text: cargo,
                      ),
                    if (departamento.isNotEmpty)
                      _HeroChip(
                        icon: Icons.apartment_rounded,
                        text: departamento,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isMobile) {
    final cards = [
      const _StatCard(
        title: 'Casos asignados',
        value: '12',
        icon: Icons.assignment_rounded,
        color: AppConfig.azulClaro,
      ),
      const _StatCard(
        title: 'Pendientes',
        value: '5',
        icon: Icons.pending_actions_rounded,
        color: AppConfig.naranja,
      ),
      const _StatCard(
        title: 'En revisión',
        value: '4',
        icon: Icons.autorenew_rounded,
        color: AppConfig.azulOscuro,
      ),
      const _StatCard(
        title: 'Resueltos',
        value: '3',
        icon: Icons.check_circle_rounded,
        color: AppConfig.verde,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
          const SizedBox(height: 12),
          cards[3],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildMobileActions(Map<String, dynamic> userData) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.assignment_rounded,
          title: 'Mis casos',
          subtitle: 'Consulta y actualiza tus casos asignados.',
          color: AppConfig.azulClaro,
          onTap: () => _goTo(MisCasosScreen(userData: userData)),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.flag_rounded,
          title: 'Nuevos reportes',
          subtitle: 'Revisa reportes disponibles para atender.',
          color: AppConfig.rojo,
          onTap: () => _goTo(NuevosReportesScreen(userData: userData)),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.map_rounded,
          title: 'Mapa de casos',
          subtitle: 'Visualiza la ubicación de los reportes.',
          color: AppConfig.verde,
          onTap: () => _goTo(const MapaCasosScreen()),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.person_rounded,
          title: 'Mi perfil',
          subtitle: 'Consulta tus datos institucionales.',
          color: AppConfig.azulOscuro,
          onTap: () => _goTo(MiPerfilScreen(userData: userData)),
        ),
      ],
    );
  }

  Widget _buildWebActions(Map<String, dynamic> userData) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.assignment_rounded,
            title: 'Mis casos',
            subtitle: 'Gestionar casos asignados',
            color: AppConfig.azulClaro,
            onTap: () => _goTo(MisCasosScreen(userData: userData)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.flag_rounded,
            title: 'Reportes',
            subtitle: 'Ver reportes recientes',
            color: AppConfig.rojo,
            onTap: () => _goTo(NuevosReportesScreen(userData: userData)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.map_rounded,
            title: 'Mapa',
            subtitle: 'Ubicación de casos',
            color: AppConfig.verde,
            onTap: () => _goTo(const MapaCasosScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardHeading(
            icon: Icons.history_rounded,
            title: 'Actividad reciente',
            subtitle: 'Últimos movimientos asociados a tu cuenta.',
          ),
          SizedBox(height: 16),
          _ActivityItem(
            title: 'Caso PSJ-8A4B2C9D asignado',
            time: 'Hace 1 hora',
            icon: Icons.assignment_ind_rounded,
            color: AppConfig.azulClaro,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Reporte marcado en revisión',
            time: 'Hace 3 horas',
            icon: Icons.autorenew_rounded,
            color: AppConfig.naranja,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Caso resuelto correctamente',
            time: 'Ayer',
            icon: Icons.check_circle_rounded,
            color: AppConfig.verde,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppConfig.azulOscuro,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: AppConfig.grisOscuro,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppConfig.grisOscuro,
                    fontWeight: FontWeight.w600,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConfig.grisMedio),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppConfig.grisOscuro,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppConfig.grisOscuro,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded, color: color),
              ),
            ],
          ),
        ),
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
            color: AppConfig.azulClaro.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulClaro),
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

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11.5,
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