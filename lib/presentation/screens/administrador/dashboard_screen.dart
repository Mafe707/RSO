import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/admin_auth_service.dart';
import '../../../services/denuncia_service.dart';
import '../../../services/auth_service.dart';

import 'admin_drawer.dart';
import 'admin_bottom_nav.dart';

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
      case 0: return 'Supervisión Administrativa';
      case 1: return 'Validación de Reportes';
      case 2: return 'Aprobación de Funcionarios';
      case 3: return 'Estadísticas';
      case 4: return 'Configuración';
      default: return 'Supervisión Administrativa';
    }
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0: return AdminDashboardContent(adminData: widget.adminData);
      case 1: return const ValidacionReportesScreen();
      case 2: return const AprobacionFuncionariosScreen();
      case 3: return const EstadisticasScreen();
      case 4: return const ConfiguracionScreen();
      default: return AdminDashboardContent(adminData: widget.adminData);
    }
  }

  Future<void> _logout() async {
    final adminAuthService = Provider.of<AdminAuthService>(context, listen: false);
    await adminAuthService.logoutAdmin();
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _selectIndex(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.w800)),
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

class AdminDashboardContent extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminDashboardContent({super.key, required this.adminData});

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  int _funcionariosPendientes = 0;
  int _reportesPendientesValidacion = 0;
  int _totalReportes = 0;
  int _reportesResueltos = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarKPIs();
  }

  Future<void> _cargarKPIs() async {
    final denunciaService = Provider.of<DenunciaService>(context, listen: false);

    try {
      final todasDenuncias = await denunciaService.obtenerTodasDenuncias();

      // Cargar funcionarios pendientes desde Supabase directamente
      final authService = Provider.of<AuthService>(context, listen: false);
      final pendientes = await authService.obtenerFuncionariosPendientesCount();

      if (!mounted) return;
      setState(() {
        _totalReportes = todasDenuncias.length;
        _reportesPendientesValidacion = todasDenuncias
            .where((d) => d['estado'] == 'resuelto_pendiente_validacion')
            .length;
        _reportesResueltos = todasDenuncias
            .where((d) => d['estado'] == 'resuelto_publicado')
            .length;
        _funcionariosPendientes = pendientes;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

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
                _buildHero(isMobile: isMobile, adminName: adminName, adminEmail: adminEmail),
                SizedBox(height: isMobile ? 22 : 28),
                _SectionHeader(
                  title: 'KPIs de supervisión',
                  subtitle: 'Elementos que requieren tu atención.',
                ),
                const SizedBox(height: 16),
                _buildKPIs(isMobile),
                SizedBox(height: isMobile ? 24 : 30),
                if (isMobile)
                  Column(children: [
                    _buildAlertasCard(),
                    const SizedBox(height: 18),
                    _buildResumenCard(),
                  ])
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAlertasCard()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildResumenCard()),
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
              _HeroBadge(icon: Icons.security_rounded, text: 'Supervisor Administrativo'),
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
                style: TextStyle(fontSize: isMobile ? 13 : 15, color: Colors.white.withOpacity(0.82)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroChip(icon: Icons.fact_check_rounded, text: 'Validar reportes'),
                  _HeroChip(icon: Icons.how_to_reg_rounded, text: 'Aprobar funcionarios'),
                  _HeroChip(icon: Icons.analytics_rounded, text: 'Estadísticas'),
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
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    final cards = [
      _StatCard(
        title: 'Funcionarios pendientes',
        value: '$_funcionariosPendientes',
        icon: Icons.how_to_reg_rounded,
        color: _funcionariosPendientes > 0 ? AppConfig.naranja : AppConfig.verde,
      ),
      _StatCard(
        title: 'Pendientes validación',
        value: '$_reportesPendientesValidacion',
        icon: Icons.fact_check_rounded,
        color: _reportesPendientesValidacion > 0 ? AppConfig.rojo : AppConfig.verde,
      ),
      _StatCard(
        title: 'Total reportes',
        value: '$_totalReportes',
        icon: Icons.list_alt_rounded,
        color: AppConfig.azulOscuro,
      ),
      _StatCard(
        title: 'Resueltos publicados',
        value: '$_reportesResueltos',
        icon: Icons.check_circle_rounded,
        color: AppConfig.verde,
      ),
    ];

    if (isMobile) {
      return Column(children: [
        cards[0], const SizedBox(height: 12),
        cards[1], const SizedBox(height: 12),
        cards[2], const SizedBox(height: 12),
        cards[3],
      ]);
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: cards,
    );
  }

  Widget _buildAlertasCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.notifications_active_rounded,
            title: 'Alertas pendientes',
            subtitle: 'Acciones que requieren tu revisión.',
          ),
          const SizedBox(height: 16),
          if (_funcionariosPendientes > 0)
            _AlertItem(
              title: '$_funcionariosPendientes funcionario(s) esperan aprobación',
              icon: Icons.how_to_reg_rounded,
              color: AppConfig.naranja,
            )
          else
            _AlertItem(
              title: 'Sin funcionarios pendientes de aprobación',
              icon: Icons.check_circle_rounded,
              color: AppConfig.verde,
            ),
          const Divider(height: 22),
          if (_reportesPendientesValidacion > 0)
            _AlertItem(
              title: '$_reportesPendientesValidacion reporte(s) esperan validación',
              icon: Icons.fact_check_rounded,
              color: AppConfig.rojo,
            )
          else
            _AlertItem(
              title: 'Sin reportes pendientes de validación',
              icon: Icons.check_circle_rounded,
              color: AppConfig.verde,
            ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.health_and_safety_rounded,
            title: 'Estado del sistema',
            subtitle: 'Resumen operativo de la plataforma.',
          ),
          const SizedBox(height: 16),
          const _ActivityItem(
            title: 'Autenticación administrativa',
            time: 'Activa',
            icon: Icons.verified_user_rounded,
            color: AppConfig.verde,
          ),
          const Divider(height: 22),
          const _ActivityItem(
            title: 'Gestión de reportes',
            time: 'Operando normalmente',
            icon: Icons.storage_rounded,
            color: AppConfig.azulClaro,
          ),
          const Divider(height: 22),
          const _ActivityItem(
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

// ── Widgets compartidos ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
        )),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro)),
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
    required this.title, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
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
                Text(value, style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w900, color: color,
                )),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(
                  fontSize: 12.5, color: AppConfig.grisOscuro, fontWeight: FontWeight.w600,
                )),
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

  const _AlertItem({required this.title, required this.icon, required this.color});

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
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 8)),
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

  const _CardHeading({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46, width: 46,
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
              Text(title, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
              )),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
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
    required this.title, required this.time,
    required this.icon, required this.color,
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
              Text(time, style: TextStyle(fontSize: 11.5, color: AppConfig.grisOscuro)),
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
          Text(text, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
          )),
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
          Text(text, style: const TextStyle(
            fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}