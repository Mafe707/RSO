import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../models/zona_riesgo_model.dart';
import '../models/hotspot_alert_model.dart';
import '../services/prediccion_service.dart';

// Pantalla de mapa de zonas para CIUDADANOS.
// Lenguaje amigable: sin términos técnicos de ML.
// Muestra: zonas según nivel de actividad, alertas activas, resumen simple.
// Navegar desde: CiudadanoBottomNav (si tienes pestaña de mapa) o drawer.
class PrediccionZonasScreen extends StatefulWidget {
  const PrediccionZonasScreen({super.key});

  @override
  State<PrediccionZonasScreen> createState() =>
      _PrediccionZonasScreenState();
}

class _PrediccionZonasScreenState extends State<PrediccionZonasScreen> {
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrediccionService>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Zonas de Actividad',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
      ),
      body: Consumer<PrediccionService>(
        builder: (context, svc, _) {
          if (svc.cargando) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando zonas de la ciudad...'),
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

          return isMobile
              ? _buildMobile(svc)
              : _buildWeb(svc);
        },
      ),
    );
  }

  Widget _buildMobile(PrediccionService svc) {
    return RefreshIndicator(
      onRefresh: svc.recargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildAlertasBanner(svc),
            _buildMapaSimulado(svc),
            _buildResumenSimple(svc),
            _buildListaZonas(svc, isMobile: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWeb(PrediccionService svc) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildAlertasBanner(svc),
                    Expanded(child: _buildMapaSimulado(svc)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildResumenSimple(svc),
                    const SizedBox(height: 16),
                    Expanded(child: _buildListaZonas(svc, isMobile: false)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertasBanner(PrediccionService svc) {
    if (svc.alertas.isEmpty) return const SizedBox.shrink();
    final critica =
        svc.alertas.firstWhere((a) => a.esCritica, orElse: () => svc.alertas.first);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: critica.esCritica
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: critica.esCritica
              ? const Color(0xFFE53935)
              : const Color(0xFFFB8C00),
        ),
      ),
      child: Row(
        children: [
          Icon(
            critica.esCritica
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: critica.esCritica
                ? const Color(0xFFE53935)
                : const Color(0xFFFB8C00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${svc.alertas.length} zona${svc.alertas.length > 1 ? 's' : ''} '
              'con actividad inusual. ${critica.zonaNombre} es la más activa.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: critica.esCritica
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mapa visual simulado con celdas de colores por riesgo.
  // Para integrar Google Maps real: reemplaza este widget con GoogleMap()
  // y usa svc.zonas para crear marcadores con BitmapDescriptor de color.
  Widget _buildMapaSimulado(PrediccionService svc) {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFE8F5E9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Fondo tipo mapa
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCEFFF), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: const Size(double.infinity, 320),
              painter: _MapaGridPainter(svc.zonas),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_city, size: 14,
                        color: AppConfig.azulOscuro),
                    SizedBox(width: 4),
                    Text('Pasto, Nariño',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: _buildLeyenda(),
            ),
            // Nota de integración Google Maps
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📍 Vista de zonas',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem('Alta actividad', const Color(0xFFE53935)),
          const SizedBox(height: 3),
          _legendItem('Actividad media', const Color(0xFFFB8C00)),
          const SizedBox(height: 3),
          _legendItem('Actividad baja', const Color(0xFF43A047)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildResumenSimple(PrediccionService svc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
              child: _ResumenCard(
            icon: Icons.map_outlined,
            label: 'Zonas\nanalizadas',
            valor: '${svc.totalZonasAnalizadas}',
            color: AppConfig.azulOscuro,
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _ResumenCard(
            icon: Icons.warning_amber_rounded,
            label: 'Alta\nactividad',
            valor: '${svc.zonasAltoRiesgo}',
            color: const Color(0xFFE53935),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _ResumenCard(
            icon: Icons.notifications_active_outlined,
            label: 'Alertas\nactivas',
            valor: '${svc.alertasActivas}',
            color: const Color(0xFFFB8C00),
          )),
        ],
      ),
    );
  }

  Widget _buildListaZonas(PrediccionService svc, {required bool isMobile}) {
    final zonasTop = svc.zonas.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Zonas con más reportes',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppConfig.azulOscuro,
            ),
          ),
        ),
        ...zonasTop.map((z) => _ZonaCiudadanoCard(zona: z)),
      ],
    );
  }
}

// Pinta el grid de zonas sobre el mapa simulado
class _MapaGridPainter extends CustomPainter {
  final List<ZonaRiesgo> zonas;

  const _MapaGridPainter(this.zonas);

  @override
  void paint(Canvas canvas, Size size) {
    // Bounds del área de Pasto a representar
    const latMin = 1.196;
    const latMax = 1.240;
    const lngMin = -77.305;
    const lngMax = -77.265;

    for (final zona in zonas) {
      final x = ((zona.lngCentro - lngMin) / (lngMax - lngMin)) * size.width;
      final y = ((latMax - zona.latCentro) / (latMax - latMin)) * size.height;

      final radio = 12.0 + (zona.reportesHistoricos / 10).clamp(0, 20);
      final color = zona.colorRiesgo;

      // Círculo de fondo translúcido
      canvas.drawCircle(
        Offset(x, y),
        radio,
        Paint()..color = color.withOpacity(0.25),
      );
      // Punto central
      canvas.drawCircle(
        Offset(x, y),
        radio * 0.5,
        Paint()..color = color.withOpacity(0.85),
      );
      // Alerta: anillo pulsante visual
      if (zona.alertaActiva) {
        canvas.drawCircle(
          Offset(x, y),
          radio * 1.4,
          Paint()
            ..color = color.withOpacity(0.15)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapaGridPainter old) =>
      old.zonas != zonas;
}

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ZonaCiudadanoCard extends StatelessWidget {
  final ZonaRiesgo zona;

  const _ZonaCiudadanoCard({required this.zona});

  String _labelActividad(NivelRiesgo nivel) {
    switch (nivel) {
      case NivelRiesgo.alto:
        return 'Alta actividad';
      case NivelRiesgo.medio:
        return 'Actividad media';
      case NivelRiesgo.bajo:
        return 'Baja actividad';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppConfig.grisMedio),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: zona.colorRiesgo.withOpacity(0.12),
          child: Icon(Icons.location_on_rounded, color: zona.colorRiesgo),
        ),
        title: Text(
          zona.zonaNombre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${zona.reportesHistoricos} reporte${zona.reportesHistoricos != 1 ? 's' : ''} registrados',
              style: const TextStyle(fontSize: 12),
            ),
            if (zona.alertaActiva && zona.mensajeAlerta != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: zona.colorRiesgo.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _labelActividad(zona.nivelRiesgo),
            style: TextStyle(
              fontSize: 10.5,
              color: zona.colorRiesgo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        isThreeLine: zona.alertaActiva,
      ),
    );
  }
}