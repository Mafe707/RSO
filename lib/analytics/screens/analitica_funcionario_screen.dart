import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../../presentation/screens/funcionario/login_screen.dart';
import '../../presentation/screens/funcionario/funcionario_bottom_nav.dart';
import '../../presentation/screens/funcionario/funcionario_drawer.dart';
import '../models/zona_riesgo_model.dart';
import '../models/hotspot_alert_model.dart';
import '../services/prediccion_service.dart';

// Pantalla de analítica predictiva para FUNCIONARIOS.
// Muestra: estadísticas técnicas, niveles de riesgo ML, probabilidades,
// alertas de hotspots, tabla de zonas con métricas detalladas.
// Acceso desde: FuncionarioDrawer o MapaCasosScreen (pestaña analítica).
class AnaliticaFuncionarioScreen extends StatefulWidget {
  const AnaliticaFuncionarioScreen({super.key});

  @override
  State<AnaliticaFuncionarioScreen> createState() =>
      _AnaliticaFuncionarioScreenState();
}

class _AnaliticaFuncionarioScreenState
    extends State<AnaliticaFuncionarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrediccionService>().inicializar();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Analítica Predictiva',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
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
            onPressed: () =>
                context.read<PrediccionService>().recargar(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Zonas'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alertas'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Resumen'),
          ],
        ),
      ),
      drawer: isMobile
          ? null
          : null, // Conecta aquí tu FuncionarioDrawer si aplica
      body: Consumer<PrediccionService>(
        builder: (context, svc, _) {
          if (svc.cargando) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ejecutando modelo predictivo...'),
                ],
              ),
            );
          }

          if (svc.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(svc.error!,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: svc.recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabs,
            children: [
              _buildTabZonas(svc),
              _buildTabAlertas(svc),
              _buildTabResumen(svc),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
        (route) => false,
      );
    }
  }

  // ─── Tab 1: Zonas ─────────────────────────────────────────────────────────
  Widget _buildTabZonas(PrediccionService svc) {
    return RefreshIndicator(
      onRefresh: svc.recargar,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildFuenteBadge(svc),
          const SizedBox(height: 12),
          _buildMapaConZonas(svc),
          const SizedBox(height: 16),
          _buildFilaEstadisticas(svc),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Detalle por zona',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppConfig.azulOscuro),
            ),
          ),
          ...svc.zonas.map((z) => _ZonaFuncionarioCard(zona: z)),
        ],
      ),
    );
  }

  Widget _buildFuenteBadge(PrediccionService svc) {
    final labels = {
      'sintetico': ('Datos sintéticos', AppConfig.azulClaro),
      'mixto': ('Datos mixtos (real + sintético)', AppConfig.naranja),
      'real': ('Datos reales de Supabase', AppConfig.verde),
    };
    final info = labels[svc.fuente] ??
        ('Fuente desconocida', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.$2.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.dataset_outlined, color: info.$2, size: 16),
          const SizedBox(width: 8),
          Text(
            'Fuente: ${info.$1} · ${svc.totalReportesUsados} reportes',
            style: TextStyle(
                color: info.$2,
                fontWeight: FontWeight.w600,
                fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaConZonas(PrediccionService svc) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFCFE2F3), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: const Size(double.infinity, 280),
              painter: _MapaZonasPainter(svc.zonas),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _MapTag('📍 Pasto, Nariño'),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _MapTag('Modelo RF activo ✓'),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: _buildLeyendaTecnica(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyendaTecnica() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow('Riesgo Alto', const Color(0xFFE53935)),
          const SizedBox(height: 3),
          _legendRow('Riesgo Medio', const Color(0xFFFB8C00)),
          const SizedBox(height: 3),
          _legendRow('Riesgo Bajo', const Color(0xFF43A047)),
        ],
      ),
    );
  }

  Widget _legendRow(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFilaEstadisticas(PrediccionService svc) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
          label: 'Zonas\nAnalizadas',
          valor: '${svc.totalZonasAnalizadas}',
          icon: Icons.grid_view_rounded,
          color: AppConfig.azulOscuro,
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
          label: 'Riesgo\nAlto',
          valor: '${svc.zonasAltoRiesgo}',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFE53935),
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
          label: 'Alertas\nActivas',
          valor: '${svc.alertasActivas}',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFFFB8C00),
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
          label: 'Reportes\nUsados',
          valor: '${svc.totalReportesUsados}',
          icon: Icons.assessment_rounded,
          color: AppConfig.verde,
        )),
      ],
    );
  }

  // ─── Tab 2: Alertas ───────────────────────────────────────────────────────
  Widget _buildTabAlertas(PrediccionService svc) {
    if (svc.alertas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: AppConfig.verde),
            SizedBox(height: 12),
            Text('Sin alertas activas',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(height: 6),
            Text('Todas las zonas están dentro de parámetros normales.',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: svc.alertas.length,
      itemBuilder: (context, i) {
        final alerta = svc.alertas[i];
        return _AlertaCard(alerta: alerta);
      },
    );
  }

  // ─── Tab 3: Resumen estadístico ───────────────────────────────────────────
  Widget _buildTabResumen(PrediccionService svc) {
    // Conteo por nivel
    final alto = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.alto).length;
    final medio = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.medio).length;
    final bajo = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.bajo).length;

    // Categorías predominantes
    final catConteo = <String, int>{};
    for (final z in svc.zonas) {
      catConteo[z.categoriaPredominante] =
          (catConteo[z.categoriaPredominante] ?? 0) + 1;
    }
    final catOrdenadas = catConteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeccionTitle('Distribución por nivel de riesgo'),
          const SizedBox(height: 10),
          _buildBarraRiesgo('Riesgo Alto', alto,
              svc.totalZonasAnalizadas, const Color(0xFFE53935)),
          const SizedBox(height: 8),
          _buildBarraRiesgo('Riesgo Medio', medio,
              svc.totalZonasAnalizadas, const Color(0xFFFB8C00)),
          const SizedBox(height: 8),
          _buildBarraRiesgo('Riesgo Bajo', bajo,
              svc.totalZonasAnalizadas, const Color(0xFF43A047)),
          const SizedBox(height: 24),
          _buildSeccionTitle('Categorías más frecuentes por zona'),
          const SizedBox(height: 10),
          ...catOrdenadas.take(6).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildBarraCategoria(
                    e.key, e.value, svc.totalZonasAnalizadas),
              )),
          const SizedBox(height: 24),
          _buildSeccionTitle('Top 5 zonas críticas'),
          const SizedBox(height: 10),
          ...svc.zonas
              .where((z) => z.nivelRiesgo == NivelRiesgo.alto)
              .take(5)
              .map((z) => _TopZonaRow(zona: z)),
          const SizedBox(height: 16),
          _buildInformacionModelo(svc),
        ],
      ),
    );
  }

  Widget _buildSeccionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppConfig.azulOscuro,
      ),
    );
  }

  Widget _buildBarraRiesgo(
      String label, int valor, int total, Color color) {
    final pct = total > 0 ? valor / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$valor zona${valor != 1 ? 's' : ''} '
                '(${(pct * 100).toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraCategoria(String cat, int valor, int total) {
    final pct = total > 0 ? valor / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(cat,
                    style:
                        const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
            Text('$valor',
                style: const TextStyle(
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppConfig.azulOscuro.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(AppConfig.azulClaro),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildInformacionModelo(PrediccionService svc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppConfig.azulOscuro),
              SizedBox(width: 6),
              Text('Información del modelo',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppConfig.azulOscuro)),
            ],
          ),
          const Divider(height: 16),
          _infoRow('Algoritmo', 'Random Forest (clasificación)'),
          _infoRow('Variables', '12 features por reporte'),
          _infoRow('Clases', 'Bajo / Medio / Alto'),
          _infoRow('Datos fuente', svc.fuente),
          _infoRow('Reportes usados', '${svc.totalReportesUsados}'),
          _infoRow('Clustering', 'Grid geoespacial ~330m × 330m'),
          _infoRow('Ciudad', 'Pasto, Nariño, Colombia'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            child: Text(valor,
                style: TextStyle(
                    color: AppConfig.grisOscuro, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Painter del mapa de zonas para funcionario ────────────────────────────
class _MapaZonasPainter extends CustomPainter {
  final List<ZonaRiesgo> zonas;

  const _MapaZonasPainter(this.zonas);

  @override
  void paint(Canvas canvas, Size size) {
    const latMin = 1.196;
    const latMax = 1.240;
    const lngMin = -77.305;
    const lngMax = -77.265;

    for (final zona in zonas) {
      final x =
          ((zona.lngCentro - lngMin) / (lngMax - lngMin)) * size.width;
      final y =
          ((latMax - zona.latCentro) / (latMax - latMin)) * size.height;
      final radio = 10.0 +
          (zona.reportesHistoricos / 8.0).clamp(0.0, 24.0);
      final color = zona.colorRiesgo;

      canvas.drawCircle(
          Offset(x, y), radio, Paint()..color = color.withOpacity(0.2));
      canvas.drawCircle(
          Offset(x, y), radio * 0.55, Paint()..color = color.withOpacity(0.9));

      if (zona.alertaActiva) {
        canvas.drawCircle(
          Offset(x, y),
          radio * 1.6,
          Paint()
            ..color = color.withOpacity(0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      // Label de probabilidad
      if (zona.nivelRiesgo == NivelRiesgo.alto) {
        final tp = TextPainter(
          text: TextSpan(
            text: zona.porcentaje,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y + radio + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapaZonasPainter old) =>
      old.zonas != zonas;
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────

class _MapTag extends StatelessWidget {
  final String text;
  const _MapTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9.5, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ZonaFuncionarioCard extends StatelessWidget {
  final ZonaRiesgo zona;

  const _ZonaFuncionarioCard({required this.zona});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: zona.colorRiesgo.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: zona.colorRiesgo.withOpacity(0.12),
                  child: Icon(Icons.location_on_rounded,
                      color: zona.colorRiesgo, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zona.zonaNombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      Text(
                          'Grid: ${zona.gridId}',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppConfig.grisOscuro)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: zona.colorRiesgo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Riesgo ${zona.labelRiesgo}',
                    style: TextStyle(
                      fontSize: 11,
                      color: zona.colorRiesgo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                _MetricaChip(
                  label: 'Reportes totales',
                  valor: '${zona.reportesHistoricos}',
                ),
                const SizedBox(width: 8),
                _MetricaChip(
                  label: 'Últimas 48h',
                  valor: '${zona.reportesUltimas48h}',
                  destacado: zona.reportesUltimas48h >= 5,
                ),
                const SizedBox(width: 8),
                _MetricaChip(
                  label: 'Prob. alta',
                  valor: zona.porcentaje,
                  destacado: zona.probabilidadAlto >= 0.6,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Categoría predominante: ${zona.categoriaPredominante}',
              style: TextStyle(
                  fontSize: 11.5,
                  color: AppConfig.grisOscuro),
            ),
            if (zona.alertaActiva && zona.mensajeAlerta != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: zona.colorRiesgo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: zona.colorRiesgo, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          zona.mensajeAlerta!,
                          style: TextStyle(
                            fontSize: 11,
                            color: zona.colorRiesgo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricaChip extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacado;

  const _MetricaChip({
    required this.label,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: destacado
              ? const Color(0xFFE53935).withOpacity(0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: destacado
                ? const Color(0xFFE53935).withOpacity(0.3)
                : AppConfig.grisMedio,
          ),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: destacado
                    ? const Color(0xFFE53935)
                    : AppConfig.azulOscuro,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final HotspotAlert alerta;

  const _AlertaCard({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final color = alerta.esCritica
        ? const Color(0xFFE53935)
        : const Color(0xFFFB8C00);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                alerta.esCritica
                    ? Icons.warning_rounded
                    : Icons.info_outline_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alerta.zonaNombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          alerta.esCritica ? 'CRÍTICA' : 'ALERTA',
                          style: TextStyle(
                              fontSize: 9.5,
                              color: color,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(alerta.mensaje,
                      style: TextStyle(
                          fontSize: 12.5, color: color)),
                  const SizedBox(height: 6),
                  Text(
                    '${alerta.reportesEnVentana} reportes en ${alerta.ventanaHoras}h · '
                    '${alerta.generadaEn.day}/${alerta.generadaEn.month}/${alerta.generadaEn.year}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopZonaRow extends StatelessWidget {
  final ZonaRiesgo zona;

  const _TopZonaRow({required this.zona});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: zona.colorRiesgo,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              zona.zonaNombre,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${zona.reportesHistoricos} rep.',
            style: TextStyle(color: AppConfig.grisOscuro),
          ),
          const SizedBox(width: 10),
          Text(
            zona.porcentaje,
            style: TextStyle(
              color: zona.colorRiesgo,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}