import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/admin_auth_service.dart';
import '../../../services/denuncia_service.dart';
import '../../../services/auth_service.dart';

import 'admin_drawer.dart';
import 'admin_bottom_nav.dart';

import 'login_screen.dart';
import 'gestion_reportes_screen.dart';
import 'gestion_usuarios_screen.dart';
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

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Supervisión Administrativa';
      case 1:
        return 'Validación de Reportes';
      case 2:
        return 'Gestión de Funcionarios';
      case 3:
        return 'Estadísticas';
      case 4:
        return 'Configuración';
      default:
        return 'Supervisión Administrativa';
    }
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardContent(
          adminData: widget.adminData,
          onNavigate: _selectIndex,
        );
      case 1:
        return const ValidacionReportesScreen();
      case 2:
        return const GestionFuncionariosScreen();
      case 3:
        return const EstadisticasScreen();
      case 4:
        return const ConfiguracionScreen();
      default:
        return AdminDashboardContent(
          adminData: widget.adminData,
          onNavigate: _selectIndex,
        );
    }
  }

  Future<void> _logout() async {
    final adminAuthService =
        Provider.of<AdminAuthService>(context, listen: false);

    await adminAuthService.logoutAdmin();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(),
      ),
      (route) => false,
    );
  }

  void _selectIndex(int index) => setState(() => _selectedIndex = index);

  void _refreshCurrentScreen() {
    if (_selectedIndex == 4) return;
    setState(() {});
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
          if (_selectedIndex != 4)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Actualizar',
              onPressed: _refreshCurrentScreen,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
        onRefresh: _refreshCurrentScreen,
      ),
      body: _getScreen(),
    );
  }
}

class AdminDashboardContent extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final ValueChanged<int>? onNavigate;

  const AdminDashboardContent({
    super.key,
    required this.adminData,
    this.onNavigate,
  });

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  int _funcionariosPendientes = 0;
  int _reportesPendientesValidacion = 0;
  int _totalReportes = 0;
  int _reportesResueltos = 0;
  bool _cargando = true;
  List<Map<String, dynamic>> _actividadReciente = [];

  @override
  void initState() {
    super.initState();
    _cargarKPIs();
  }

  Future<void> _cargarKPIs() async {
    final denunciaService = Provider.of<DenunciaService>(context, listen: false);

    try {
      final todasDenuncias = await denunciaService.obtenerTodasDenuncias();
      final authService = Provider.of<AuthService>(context, listen: false);
      final pendientes = await authService.obtenerFuncionariosPendientesCount();

      final publicados = todasDenuncias
          .where((d) => d['estado'] == 'resuelto_publicado')
          .toList();

      publicados.sort((a, b) {
        final fa = DateTime.tryParse(a['actualizado_en']?.toString() ?? '') ??
            DateTime(2000);
        final fb = DateTime.tryParse(b['actualizado_en']?.toString() ?? '') ??
            DateTime(2000);
        return fb.compareTo(fa);
      });

      if (!mounted) return;
      setState(() {
        _totalReportes = todasDenuncias.length;
        _reportesPendientesValidacion = todasDenuncias
            .where((d) => d['estado'] == 'resuelto_pendiente_validacion')
            .length;
        _reportesResueltos = publicados.length;
        _funcionariosPendientes = pendientes;
        _actividadReciente = publicados.take(5).toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final adminName = widget.adminData['nombre']?.toString() ?? 'Supervisor';
    final adminEmail = widget.adminData['correo']?.toString() ?? '';

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
                const _SectionHeader(
                  title: 'KPIs de supervisión',
                  subtitle: 'Elementos que requieren tu atención.',
                ),
                const SizedBox(height: 16),
                _buildKPIs(isMobile),
                SizedBox(height: isMobile ? 24 : 30),
                const _SectionHeader(
                  title: 'Accesos directos',
                  subtitle: 'Navega rápidamente a cualquier sección.',
                ),
                const SizedBox(height: 16),
                _buildAccesosDirectos(isMobile),
                SizedBox(height: isMobile ? 24 : 30),
                if (isMobile)
                  Column(
                    children: [
                      _buildAlertasCard(),
                      const SizedBox(height: 18),
                      _buildActividadRecienteCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAlertasCard()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildActividadRecienteCard()),
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
            bottom: -8,
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
                text: 'Supervisor Administrativo',
              ),
              const SizedBox(height: 18),
              Text(
                'Bienvenido, $adminName 👋',
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
                    icon: Icons.fact_check_rounded,
                    text: 'Validación',
                  ),
                  _HeroChip(
                    icon: Icons.manage_accounts_rounded,
                    text: 'Funcionarios',
                  ),
                  _HeroChip(
                    icon: Icons.bar_chart_rounded,
                    text: 'Estadísticas',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs(bool isMobile) {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final tasa = _totalReportes > 0
        ? ((_reportesResueltos / _totalReportes) * 100).round()
        : 0;

    final cards = [
      _StatCard(
        title: 'Func. pendientes',
        value: '$_funcionariosPendientes',
        icon: Icons.person_add_rounded,
        color: AppConfig.naranja,
      ),
      _StatCard(
        title: 'Pend. validación',
        value: '$_reportesPendientesValidacion',
        icon: Icons.fact_check_rounded,
        color: AppConfig.rojo,
      ),
      _StatCard(
        title: 'Total reportes',
        value: '$_totalReportes',
        icon: Icons.flag_rounded,
        color: AppConfig.azulClaro,
      ),
      _StatCard(
        title: 'Tasa resolución',
        value: '$tasa%',
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

  Widget _buildAccesosDirectos(bool isMobile) {
    final accesos = [
      _AccesoDirectoData(
        icon: Icons.fact_check_rounded,
        title: 'Validación de Reportes',
        subtitle: 'Aprueba o devuelve reportes',
        color: AppConfig.rojo,
        index: 1,
        badge: _reportesPendientesValidacion > 0
            ? '$_reportesPendientesValidacion'
            : null,
      ),
      _AccesoDirectoData(
        icon: Icons.manage_accounts_rounded,
        title: 'Gestión de Funcionarios',
        subtitle: 'Aprueba registros de personal',
        color: AppConfig.azulClaro,
        index: 2,
        badge: _funcionariosPendientes > 0 ? '$_funcionariosPendientes' : null,
      ),
      _AccesoDirectoData(
        icon: Icons.bar_chart_rounded,
        title: 'Estadísticas',
        subtitle: 'Métricas y análisis del sistema',
        color: AppConfig.verde,
        index: 3,
      ),
      _AccesoDirectoData(
        icon: Icons.settings_rounded,
        title: 'Configuración',
        subtitle: 'Tipos de invasión y ajustes',
        color: AppConfig.naranja,
        index: 4,
      ),
    ];

    if (isMobile) {
      return Column(
        children: accesos
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AccesoDirectoCard(
                  data: a,
                  onTap: () => widget.onNavigate?.call(a.index),
                ),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: accesos
          .map(
            (a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: accesos.last == a ? 0 : 14),
                child: _AccesoDirectoCard(
                  data: a,
                  onTap: () => widget.onNavigate?.call(a.index),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAlertasCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.notifications_active_rounded,
            title: 'Acciones pendientes',
            subtitle: 'Elementos que requieren atención.',
          ),
          const SizedBox(height: 18),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_funcionariosPendientes > 0)
              _AlertItem(
                title:
                    '$_funcionariosPendientes funcionario${_funcionariosPendientes != 1 ? 's' : ''} esperando aprobación',
                icon: Icons.person_add_rounded,
                color: AppConfig.naranja,
              ),
            if (_funcionariosPendientes > 0 &&
                _reportesPendientesValidacion > 0)
              const SizedBox(height: 10),
            if (_reportesPendientesValidacion > 0)
              _AlertItem(
                title:
                    '$_reportesPendientesValidacion reporte${_reportesPendientesValidacion != 1 ? 's' : ''} pendiente${_reportesPendientesValidacion != 1 ? 's' : ''} de validación',
                icon: Icons.fact_check_rounded,
                color: AppConfig.rojo,
              ),
            if (_funcionariosPendientes == 0 &&
                _reportesPendientesValidacion == 0)
              _AlertItem(
                title: 'Todo al día. Sin acciones pendientes.',
                icon: Icons.check_circle_rounded,
                color: AppConfig.verde,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActividadRecienteCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.public_rounded,
            title: 'Actividad reciente',
            subtitle: 'Últimos 5 reportes publicados.',
          ),
          const SizedBox(height: 18),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_actividadReciente.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay reportes publicados aún.',
                style: TextStyle(color: AppConfig.grisOscuro),
              ),
            )
          else
            ...List.generate(_actividadReciente.length, (i) {
              final r = _actividadReciente[i];
              return Column(
                children: [
                  if (i > 0) const Divider(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppConfig.verde.withOpacity(0.1),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppConfig.verde,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['codigo_unico']?.toString() ?? '—',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r['categoria']?.toString() ?? '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConfig.grisOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatFecha(r['actualizado_en']),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConfig.grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _AccesoDirectoData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int index;
  final String? badge;

  const _AccesoDirectoData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.index,
    this.badge,
  });
}

class _AccesoDirectoCard extends StatelessWidget {
  final _AccesoDirectoData data;
  final VoidCallback onTap;

  const _AccesoDirectoCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConfig.grisMedio),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(data.icon, color: data.color, size: 26),
                ),
                if (data.badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: data.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppConfig.grisOscuro,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

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
          style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro),
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

class _AlertItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AlertItem({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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