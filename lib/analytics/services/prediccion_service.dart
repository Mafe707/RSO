import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reporte_sintetico_model.dart';
import '../models/zona_riesgo_model.dart';
import '../models/hotspot_alert_model.dart';
import 'synthetic_reports_service.dart';
import 'spatial_analysis_service.dart';
import 'random_forest_service.dart';

class PrediccionService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final SyntheticReportsService _synthetic = SyntheticReportsService();
  final SpatialAnalysisService  _spatial   = SpatialAnalysisService();
  final RandomForestService     _rf        = RandomForestService();

  static const int _minRealesParaNoSinteticos = 50;
  static const int _nSinteticosDefault        = 400;

  List<ZonaRiesgo>     _zonas        = [];
  List<HotspotAlert>   _alertas      = [];
  List<ReporteSintetico> _todosReportes = [];
  bool    _cargando = false;
  String? _error;
  String  _fuente   = 'sintetico';

  List<ZonaRiesgo>      get zonas          => _zonas;
  List<HotspotAlert>    get alertas        => _alertas;
  List<ReporteSintetico> get todosReportes => _todosReportes;
  bool    get cargando           => _cargando;
  String? get error              => _error;
  String  get fuente             => _fuente;

  int get zonasAltoRiesgo      => _zonas.where((z) => z.nivelRiesgo == NivelRiesgo.alto).length;
  int get alertasActivas       => _alertas.length;
  int get totalReportesUsados  => _todosReportes.length;
  int get totalZonasAnalizadas => _zonas.length;

  PrediccionService(this._supabase);

  Future<void> inicializar() async {
    if (_cargando) return;
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      await _rf.cargar();

      final reales = await _cargarRealesDesdeSupabase();

      List<ReporteSintetico> reportes;
      if (reales.length >= _minRealesParaNoSinteticos) {
        reportes = reales;
        _fuente  = 'real';
      } else if (reales.isNotEmpty) {
        final sinteticos = _synthetic.generar(_nSinteticosDefault - reales.length);
        reportes = [...reales, ...sinteticos];
        _fuente  = 'mixto';
      } else {
        reportes = _synthetic.generar(_nSinteticosDefault);
        _fuente  = 'sintetico';
      }

      _todosReportes = reportes;

      // Siempre calcular en tiempo real para usar los hotspots reales del JSON
      _zonas = await _calcularZonasEnTiempoReal(reportes);

      final statsZonas = _spatial.calcularZonas(reportes);
      _alertas = _spatial.generarAlertas(statsZonas);

      _zonas.sort((a, b) {
        const orden = {NivelRiesgo.alto: 0, NivelRiesgo.medio: 1, NivelRiesgo.bajo: 2};
        return orden[a.nivelRiesgo]!.compareTo(orden[b.nivelRiesgo]!);
      });
    } catch (e) {
      _error = 'Error al cargar analítica: $e';
      debugPrint(_error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<List<ReporteSintetico>> _cargarRealesDesdeSupabase() async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select('id, codigo_unico, ubicacion, latitud, longitud, '
              'categoria, descripcion, estado, creado_en')
          .not('latitud', 'is', null)
          .not('longitud', 'is', null)
          .order('creado_en', ascending: false)
          .limit(1000);
      return (response as List<dynamic>)
          .map((m) => ReporteSintetico.fromSupabase(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('No se pudieron cargar datos reales: $e');
      return [];
    }
  }

  Future<List<ZonaRiesgo>> _calcularZonasEnTiempoReal(
      List<ReporteSintetico> reportes) async {
    final statsZonas = _spatial.calcularZonas(reportes);
    final hotspots   = _spatial.detectarHotspots(statsZonas);
    final ahora      = DateTime.now();
    final limite48h  = ahora.subtract(const Duration(hours: 48));

    final List<ZonaRiesgo> resultado = [];

    for (final entry in statsZonas.entries.where((e) => e.value.total >= 3)) {
      final zona = entry.value;
      final (latC, lngC) = SpatialAnalysisService.gridIdToCenter(zona.gridId);

      final r48h      = zona.reportes.where((r) => r.creadoEn.isAfter(limite48h)).length;
      final esHotspot = hotspots.contains(zona.gridId);

      final features = _rf.construirFeatures(
        lat:                  latC,
        lng:                  lngC,
        categoriaPredominante: zona.categoriaPredominante,
        reportesTotales:      zona.total,
        reportes48h:          r48h,
        esHotspotReciente:    esHotspot,
        fechaRef:             ahora,
      );

      final probs    = _rf.predecir(features);
      final nivelIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      final nivel    = nivelIdx == 2
          ? NivelRiesgo.alto
          : nivelIdx == 1
              ? NivelRiesgo.medio
              : NivelRiesgo.bajo;

      bool    alerta        = false;
      String? mensajeAlerta;
      if (r48h >= 8) {
        alerta        = true;
        mensajeAlerta = 'Incremento crítico: $r48h denuncias en las últimas 48 horas';
      } else if (r48h >= 5) {
        alerta        = true;
        mensajeAlerta = 'Aumento inusual: $r48h denuncias en las últimas 48 horas';
      }

      // Nombre desde hotspots_pasto.json (coords reales de Nominatim)
      // Si falla, consulta Nominatim directamente
      final nombreZona = await _nombreZonaCercana(latC, lngC);

      resultado.add(ZonaRiesgo(
        gridId:                zona.gridId,
        zonaNombre:            nombreZona,
        latCentro:             latC,
        lngCentro:             lngC,
        nivelRiesgo:           nivel,
        probabilidadAlto:      probs[2],
        reportesHistoricos:    zona.total,
        reportesUltimas48h:    r48h,
        categoriaPredominante: zona.categoriaPredominante,
        alertaActiva:          alerta,
        mensajeAlerta:         mensajeAlerta,
      ));
    }

    return resultado;
  }

  Future<String> _nombreZonaCercana(double lat, double lng) async {
    // 1. Usar hotspots con coords reales cargados desde hotspots_pasto.json
    final hotspots = _rf.hotspots;
    if (hotspots.isNotEmpty) {
      double minDist = double.infinity;
      String nombre  = hotspots.first['nombre'] as String;
      for (final h in hotspots) {
        final d = SpatialAnalysisService.distanciaMetros(
          lat, lng,
          (h['lat'] as num).toDouble(),
          (h['lng'] as num).toDouble(),
        );
        if (d < minDist) {
          minDist = d;
          nombre  = h['nombre'] as String;
        }
      }
      return nombre;
    }

    // 2. Fallback: consultar Nominatim directamente
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lng&zoom=16&addressdetails=1&accept-language=es',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'com.rso.app/1.0',
        'Accept':     'application/json',
      });
      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final barrio  =
            address['neighbourhood']?.toString().trim() ??
            address['suburb']?.toString().trim() ??
            address['quarter']?.toString().trim() ??
            address['city_district']?.toString().trim();
        if (barrio != null && barrio.isNotEmpty) return barrio;
      }
    } catch (_) {}

    return 'Pasto, Nariño';
  }

  Future<void> recargar() => inicializar();
}