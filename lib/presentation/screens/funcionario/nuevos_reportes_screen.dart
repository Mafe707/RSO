import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../../../core/supabase/supabase_config.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';
import 'login_screen.dart';

class NuevosReportesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NuevosReportesScreen({super.key, required this.userData});

  @override
  State<NuevosReportesScreen> createState() => _NuevosReportesScreenState();
}

class _NuevosReportesScreenState extends State<NuevosReportesScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _reportes = [];
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final response = await _supabase
          .from('denuncias')
          .select()
          .filter('funcionario_id', 'is', null)
          .order('creado_en', ascending: false);

      setState(() {
        _reportes = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error al cargar reportes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _asignarACaso(Map<String, dynamic> reporte) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final funcionarioData = authService.funcionarioData;

    if (funcionarioData == null) {
      _showError('No se pudo obtener tu información de funcionario');
      return;
    }

    final funcionarioId = funcionarioData['id'];
    final denunciaId = reporte['id'];

    try {
      await _supabase.from('denuncias').update({
        'funcionario_id': funcionarioId,
        'estado': 'en_revision',
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', denunciaId);

      setState(() {
        _reportes.removeWhere((r) => r['id'] == denunciaId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Caso ${reporte['codigo_unico']} asignado correctamente'),
            backgroundColor: AppConfig.verde,
          ),
        );
      }
    } catch (e) {
      _showError('Error al asignar caso: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo),
    );
  }

  Future<void> _cerrarSesion() async {
  final authService = Provider.of<AuthService>(context, listen: false);
  await authService.logout();
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
      (route) => false,
    );
  }
}

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  Color _getPrioridadColor(String? estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.naranja;
      case 'revision':
        return AppConfig.azulClaro;
      case 'resuelta':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _getCategoriaIcon(String? categoria) {
    switch (categoria) {
      case 'Venta informal':
        return '🛒';
      case 'Invasión vehicular':
        return '🚗';
      case 'Ocupación comercial':
        return '🏪';
      case 'Publicidad no autorizada':
        return '📢';
      default:
        return '📋';
    }
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
        centerTitle: false,
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        automaticallyImplyLeading: false,
leading: isMobile
    ? null
    : Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargarReportes,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 2,
        userData: widget.userData,
      ),
      bottomNavigationBar:
          FuncionarioBottomNav.maybe(context, currentIndex: 2),
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
  return RefreshIndicator(
    onRefresh: _cargarReportes,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        _buildHero(isMobile: true),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildSummaryCard(),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildMobileBody(),
        ),
      ],
    ),
  );
}

Widget _buildMobileBody() {
  if (_loading) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (_errorMsg != null) {
    return _EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Error',
      text: _errorMsg!,
    );
  }

  if (_reportes.isEmpty) {
    return const _EmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: 'Sin reportes nuevos',
      text: 'No hay reportes disponibles para asignación en este momento.',
    );
  }

  return Column(
    children: _reportes.map((reporte) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ReportCard(
          reporte: reporte,
          categoriaIcon: _getCategoriaIcon(reporte['categoria']),
          estadoColor: _getPrioridadColor(reporte['estado']),
          onAssign: () => _asignarACaso(reporte),
        ),
      );
    }).toList(),
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
        Expanded(flex: 6, child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg != null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error',
        text: _errorMsg!,
      );
    }

    if (_reportes.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Sin reportes nuevos',
        text: 'No hay reportes disponibles para asignación en este momento.',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarReportes,
      child: ListView.builder(
        itemCount: _reportes.length,
        itemBuilder: (context, index) {
          final reporte = _reportes[index];
          return _ReportCard(
            reporte: reporte,
            categoriaIcon: _getCategoriaIcon(reporte['categoria']),
            estadoColor: _getPrioridadColor(reporte['estado']),
            onAssign: () => _asignarACaso(reporte),
          );
        },
      ),
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
            bottom: -8,
            child: Icon(
              Icons.flag_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(
                icon: Icons.new_releases_rounded,
                text: 'Reportes sin asignar',
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
                'Reportes ciudadanos disponibles para asignación.',
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
    final total = _reportes.length;

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
            value: '$total',
            color: AppConfig.rojo,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> reporte;
  final String categoriaIcon;
  final Color estadoColor;
  final VoidCallback onAssign;

  const _ReportCard({
    required this.reporte,
    required this.categoriaIcon,
    required this.estadoColor,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = reporte['codigo_unico'] ?? 'Sin código';
    final ubicacion = reporte['ubicacion'] ?? 'Sin ubicación';
    final categoria = reporte['categoria'] ?? 'Sin categoría';
    final descripcion = reporte['descripcion'] ?? '';
    final imagenUrl = reporte['imagen_url']?.toString();
    final fecha = reporte['creado_en'] != null
        ? DateTime.tryParse(reporte['creado_en'].toString())
        : null;
    final fechaStr = fecha != null
        ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
        : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppConfig.grisMedio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagenUrl != null && imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                imagenUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    color: AppConfig.grisClaro,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppConfig.rojo.withOpacity(0.12),
                      child: Text(
                        categoriaIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            codigo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppConfig.azulOscuro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ubicacion,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (descripcion.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppConfig.grisOscuro,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _StatusChip(
                                label: categoria,
                                color: AppConfig.azulOscuro,
                              ),
                              if (fechaStr.isNotEmpty)
                                _StatusChip(
                                  label: fechaStr,
                                  color: AppConfig.azulClaro,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                    ),
                    label: const Text('Asignar a mí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.verde,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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