import 'dart:math';
import '../models/reporte_sintetico_model.dart';
import '../models/hotspot_alert_model.dart';

// Análisis espacial: agrupa reportes en celdas de ~250m,
// calcula densidades, detecta hotspots y genera alertas.
//
// Sistema de grids: divide el área urbana de Pasto en celdas de ~250m
// usando offsets y tamaño de celda en grados.
// Offset lat: 1.20 | Offset lng: -77.31 | Tamaño: 0.003 grados (~330m)
class SpatialAnalysisService {
  static const double _gridLatOffset = 1.20;
  static const double _gridLngOffset = -77.31;
  static const double _gridSize = 0.003;
  static const int _umbralAlerta48h = 5;
  static const int _umbralAlertaCritica48h = 8;

  // Convierte coordenadas a ID de celda
  static String coordsToGridId(double lat, double lng) {
    final gridLat = ((lat - _gridLatOffset) / _gridSize).floor();
    final gridLng = ((lng - _gridLngOffset) / _gridSize).floor();
    return '${gridLat}_$gridLng';
  }

  // Centro geográfico de una celda dado su ID
  static (double lat, double lng) gridIdToCenter(String gridId) {
    final partes = gridId.split('_');
    if (partes.length < 2) return (1.2136, -77.2811);
    final gLat = int.tryParse(partes[0]) ?? 0;
    final gLng = int.tryParse(partes[1]) ?? 0;
    final lat = _gridLatOffset + (gLat + 0.5) * _gridSize;
    final lng = _gridLngOffset + (gLng + 0.5) * _gridSize;
    return (lat, lng);
  }

  // Agrupa reportes por celda y calcula estadísticas por zona
  Map<String, _ZonaStats> calcularZonas(List<ReporteSintetico> reportes) {
    final Map<String, _ZonaStats> zonas = {};

    for (final r in reportes) {
      final gId = coordsToGridId(r.latitud, r.longitud);
      zonas.putIfAbsent(gId, () => _ZonaStats(gId));
      zonas[gId]!.agregar(r);
    }

    return zonas;
  }

  // Detecta hotspots: zonas con más reportes que el umbral histórico
  List<String> detectarHotspots(
    Map<String, _ZonaStats> zonas, {
    int umbralDensidad = 15,
  }) {
    return zonas.entries
        .where((e) => e.value.total >= umbralDensidad)
        .map((e) => e.key)
        .toList();
  }

  // Genera alertas para zonas que superan umbral en ventana de 48h
  List<HotspotAlert> generarAlertas(Map<String, _ZonaStats> zonas) {
    final alertas = <HotspotAlert>[];
    final ahora = DateTime.now();
    final limite48h = ahora.subtract(const Duration(hours: 48));

    for (final entry in zonas.entries) {
      final zona = entry.value;
      final en48h = zona.reportes
          .where((r) => r.creadoEn.isAfter(limite48h))
          .length;

      if (en48h >= _umbralAlerta48h) {
        // Calcular nombre de zona más cercano a hotspot conocido
        final (latC, lngC) = gridIdToCenter(zona.gridId);
        final nombreZona = _nombreZonaCercana(latC, lngC);

        alertas.add(HotspotAlert.fromZona(
          zonaId: zona.gridId,
          zonaNombre: nombreZona,
          reportes: en48h,
          ventanaHoras: 48,
        ));
      }
    }

    // Ordenar: críticas primero
    alertas.sort((a, b) =>
        b.reportesEnVentana.compareTo(a.reportesEnVentana));

    return alertas;
  }

  // Calcula distancia en metros entre dos coordenadas (Haversine simplificado)
  static double distanciaMetros(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _nombreZonaCercana(double lat, double lng) {
    const hotspots = [
      (1.2136, -77.2811, 'Centro Histórico'),
      (1.2180, -77.2760, 'La Empieza'),
      (1.2080, -77.2870, 'Lorenzo'),
      (1.2200, -77.2900, 'Obrero'),
      (1.2050, -77.2750, 'Mercado Potrerillo'),
      (1.2250, -77.2800, 'Mijitayo'),
      (1.2100, -77.2950, 'Jongovito'),
      (1.2300, -77.2700, 'Villa Flor'),
    ];

    double minDist = double.infinity;
    String nombre = 'Zona desconocida';
    for (final hs in hotspots) {
      final d = distanciaMetros(lat, lng, hs.$1, hs.$2);
      if (d < minDist) {
        minDist = d;
        nombre = hs.$3;
      }
    }
    return nombre;
  }
}

// Estadísticas acumuladas por zona durante el análisis
class _ZonaStats {
  final String gridId;
  final List<ReporteSintetico> reportes = [];

  _ZonaStats(this.gridId);

  void agregar(ReporteSintetico r) => reportes.add(r);

  int get total => reportes.length;

  String get categoriaPredominante {
    final conteo = <String, int>{};
    for (final r in reportes) {
      conteo[r.categoria] = (conteo[r.categoria] ?? 0) + 1;
    }
    return conteo.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int reportesEnVentana(Duration ventana) {
    final limite = DateTime.now().subtract(ventana);
    return reportes.where((r) => r.creadoEn.isAfter(limite)).length;
  }
}