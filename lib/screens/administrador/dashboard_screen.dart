import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/admin_auth_service.dart';

import 'admin_drawer.dart';
import 'admin_bottom_nav.dart';

import 'gestion_reportes_screen.dart';
import 'gestion_usuarios_screen.dart';
import 'gestion_zonas_screen.dart';
import 'asignaciones_screen.dart';
import 'estadisticas_screen.dart';
import 'configuracion_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminDashboardScreen({
    super.key,
    required this.adminData,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Panel de Administración';
      case 1:
        return 'Gestión de Reportes';
      case 2:
        return 'Gestión de Usuarios';
      case 3:
        return 'Gestión de Zonas';
      case 4:
        return 'Asignaciones';
      case 5:
        return 'Estadísticas';
      case 6:
        return 'Configuración';
      default:
        return 'Panel de Administración';
    }
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardContent(adminData: widget.adminData);
      case 1:
        return const GestionReportesScreen();
      case 2:
        return const GestionUsuariosScreen();
      case 3:
        return const GestionZonasScreen();
      case 4:
        return const AsignacionesScreen();
      case 5:
        return const EstadisticasScreen();
      case 6:
        return const ConfiguracionScreen();
      default:
        return AdminDashboardContent(adminData: widget.adminData);
    }
  }

  Future<void> _logout() async {
    final adminAuthService = Provider.of<AdminAuthService>(
      context,
      listen: false,
    );

    await adminAuthService.logoutAdmin();

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: isMobile,
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        actions: [
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: _logout,
            ),
        ],
      ),
      drawer: AdminDrawer.maybe(
        context,
        currentIndex: _selectedIndex,
        adminData: widget.adminData,
        onSelect: _selectIndex,
        onLogout: _logout,
      ),
      bottomNavigationBar: AdminBottomNav.maybe(
        context,
        currentIndex: _selectedIndex,
        onSelect: _selectIndex,
        onLogout: _logout,
      ),
      body: _getScreen(),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  final Map<String, dynamic> adminData;

  const AdminDashboardContent({
    super.key,
    required this.adminData,
  });

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final adminName = adminData['nombre']?.toString() ?? 'Administrador';
    final adminEmail = adminData['correo']?.toString() ?? '';

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(
                  isMobile: isMobile,
                  adminName: adminName,
                  adminEmail: adminEmail,
                ),
                SizedBox(height: isMobile ? 22 : 28),
                _SectionHeader(
                  title: 'Resumen general',
                  subtitle: 'Estado global del sistema.',
                  actionText: isMobile ? null : 'Administrador activo',
                ),
                const SizedBox(height: 16),
                _buildStats(isMobile),
                SizedBox(height: isMobile ? 24 : 30),
                if (isMobile)
                  Column(
                    children: [
                      _buildActivityCard(),
                      const SizedBox(height: 18),
                      _buildSystemCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildActivityCard()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildSystemCard()),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero({
    required bool isMobile,
    required String adminName,
    required String adminEmail,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.rojo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.rojo.withOpacity(0.18),
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
              Icons.admin_panel_settings_rounded,
              size: isMobile ? 105 : 150,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.security_rounded,
                text: 'Acceso administrativo',
              ),
              const SizedBox(height: 18),
              Text(
                'Bienvenido, $adminName',
                style: TextStyle(
                  fontSize: isMobile ? 27 : 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                adminEmail,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroChip(
                    icon: Icons.flag_rounded,
                    text: 'Control de reportes',
                  ),
                  _HeroChip(
                    icon: Icons.people_rounded,
                    text: 'Gestión de usuarios',
                  ),
                  _HeroChip(
                    icon: Icons.analytics_rounded,
                    text: 'Indicadores',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isMobile) {
    final cards = [
      const _StatCard(
        title: 'Reportes totales',
        value: '312',
        icon: Icons.list_alt_rounded,
        color: AppConfig.azulOscuro,
      ),
      const _StatCard(
        title: 'Pendientes',
        value: '45',
        icon: Icons.pending_actions_rounded,
        color: AppConfig.naranja,
      ),
      const _StatCard(
        title: 'En revisión',
        value: '28',
        icon: Icons.autorenew_rounded,
        color: AppConfig.azulClaro,
      ),
      const _StatCard(
        title: 'Resueltos',
        value: '239',
        icon: Icons.check_circle_rounded,
        color: AppConfig.verde,
      ),
      const _StatCard(
        title: 'Funcionarios',
        value: '12',
        icon: Icons.people_rounded,
        color: AppConfig.azulClaro,
      ),
      const _StatCard(
        title: 'Zonas activas',
        value: '8',
        icon: Icons.map_rounded,
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
          const SizedBox(height: 12),
          cards[4],
          const SizedBox(height: 12),
          cards[5],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.45,
      children: cards,
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
            subtitle: 'Últimos movimientos administrativos.',
          ),
          SizedBox(height: 16),
          _ActivityItem(
            title: 'Nuevo reporte PSJ-8A4B2C9D',
            time: 'Hace 5 minutos',
            icon: Icons.flag_rounded,
            color: AppConfig.rojo,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Caso asignado a Carlos Rodríguez',
            time: 'Hace 1 hora',
            icon: Icons.assignment_rounded,
            color: AppConfig.azulClaro,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Reporte PSJ-123ABC resuelto',
            time: 'Hace 3 horas',
            icon: Icons.check_circle_rounded,
            color: AppConfig.verde,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Nuevo funcionario registrado',
            time: 'Ayer',
            icon: Icons.person_add_rounded,
            color: AppConfig.azulOscuro,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardHeading(
            icon: Icons.health_and_safety_rounded,
            title: 'Estado del sistema',
            subtitle: 'Resumen operativo de la plataforma.',
          ),
          SizedBox(height: 16),
          _ActivityItem(
            title: 'Autenticación administrativa',
            time: 'Activa',
            icon: Icons.verified_user_rounded,
            color: AppConfig.verde,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Gestión de reportes',
            time: 'Operando normalmente',
            icon: Icons.storage_rounded,
            color: AppConfig.azulClaro,
          ),
          Divider(height: 22),
          _ActivityItem(
            title: 'Panel web y móvil',
            time: 'Diseño adaptable',
            icon: Icons.devices_rounded,
            color: AppConfig.rojo,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        if (actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppConfig.grisMedio),
            ),
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppConfig.azulOscuro,
                fontWeight: FontWeight.w800,
              ),
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
            color: AppConfig.rojo.withOpacity(0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.rojo),
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