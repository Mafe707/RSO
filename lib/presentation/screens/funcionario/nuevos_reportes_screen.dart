import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';

class NuevosReportesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NuevosReportesScreen({
    super.key,
    required this.userData,
  });

  @override
  State<NuevosReportesScreen> createState() => _NuevosReportesScreenState();
}

class _NuevosReportesScreenState extends State<NuevosReportesScreen> {
  final List<Map<String, dynamic>> _nuevosReportes = [
    {
      'id': 'PSJ-ABC123',
      'fecha': '15/09/2025',
      'categoria': 'Venta informal',
      'ubicacion': 'Parque Central',
      'prioridad': 'alta',
    },
    {
      'id': 'PSJ-DEF456',
      'fecha': '14/09/2025',
      'categoria': 'Invasión vehicular',
      'ubicacion': 'Calle 15',
      'prioridad': 'media',
    },
    {
      'id': 'PSJ-GHI789',
      'fecha': '14/09/2025',
      'categoria': 'Ocupación comercial',
      'ubicacion': 'Avenida Colombia',
      'prioridad': 'alta',
    },
  ];

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

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return AppConfig.rojo;
      case 'media':
        return AppConfig.naranja;
      case 'baja':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _getPrioridadText(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'baja':
        return 'Baja';
      default:
        return prioridad;
    }
  }

  void _asignarACaso(String id) {
    setState(() {
      _nuevosReportes.removeWhere((reporte) => reporte['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caso asignado correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Nuevos Reportes',
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
        currentIndex: 2,
        userData: widget.userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
        context,
        currentIndex: 2,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 16),
        Expanded(child: _buildReportsList()),
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
              const SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: _buildReportsList(),
        ),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
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
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -24,
            child: Icon(
              Icons.flag_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.new_releases_rounded,
                text: 'Reportes pendientes',
              ),
              const SizedBox(height: 18),
              Text(
                'Nuevos reportes',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Revisa los reportes ciudadanos que todavía no han sido asignados.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.5,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.insights_rounded,
            title: 'Resumen',
            subtitle: 'Reportes disponibles para asignación.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total disponibles',
            value: '${_nuevosReportes.length}',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Prioridad alta',
            value:
                '${_nuevosReportes.where((r) => r['prioridad'] == 'alta').length}',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Prioridad media',
            value:
                '${_nuevosReportes.where((r) => r['prioridad'] == 'media').length}',
            color: AppConfig.naranja,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    if (_nuevosReportes.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Sin reportes nuevos',
        text: 'No hay nuevos reportes disponibles por el momento.',
      );
    }

    return ListView.builder(
      itemCount: _nuevosReportes.length,
      itemBuilder: (context, index) {
        final reporte = _nuevosReportes[index];
        final prioridadColor = _getPrioridadColor(reporte['prioridad']);

        return _ReportCard(
          id: reporte['id'],
          fecha: reporte['fecha'],
          categoria: reporte['categoria'],
          ubicacion: reporte['ubicacion'],
          prioridad: _getPrioridadText(reporte['prioridad']),
          prioridadColor: prioridadColor,
          onAssign: () => _asignarACaso(reporte['id']),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String id;
  final String fecha;
  final String categoria;
  final String ubicacion;
  final String prioridad;
  final Color prioridadColor;
  final VoidCallback onAssign;

  const _ReportCard({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.ubicacion,
    required this.prioridad,
    required this.prioridadColor,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 520;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppConfig.grisMedio),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _content(),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: _assignButton()),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _content()),
                  const SizedBox(width: 14),
                  _assignButton(),
                ],
              ),
      ),
    );
  }

  Widget _content() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppConfig.rojo.withOpacity(0.12),
          child: const Icon(Icons.flag_rounded, color: AppConfig.rojo),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 5),
              Text(ubicacion),
              const SizedBox(height: 4),
              Text(
                categoria,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: prioridad, color: prioridadColor),
                  _StatusChip(label: fecha, color: AppConfig.azulClaro),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assignButton() {
    return ElevatedButton.icon(
      onPressed: onAssign,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Asignar a mí'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConfig.verde,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppConfig.azulClaro),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}