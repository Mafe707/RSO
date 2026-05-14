import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ml_feature_vector.dart';
import '../models/zona_riesgo_model.dart';
import 'spatial_analysis_service.dart';

class RandomForestService {
  static const String _assetPath        = 'assets/ml/modelo_rf.json';
  static const String _hotspotsPath     = 'assets/ml/hotspots_pasto.json';

  Map<String, dynamic>? _modelo;
  List<dynamic>?        _arboles;
  List<dynamic>?        _zonasPrecalculadas;
  Map<String, dynamic>? _config;
  Map<String, dynamic>? _categoriaMapping;
  List<Map<String, dynamic>> _hotspots = [];
  bool _cargado = false;

  bool get estaCargado => _cargado;
  List<Map<String, dynamic>> get hotspots => _hotspots;

  Future<void> cargar() async {
    // Cargar modelo RF
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _modelo             = json.decode(raw) as Map<String, dynamic>;
      _arboles            = _modelo!['arboles'] as List<dynamic>;
      _zonasPrecalculadas = _modelo!['zonas_precalculadas'] as List<dynamic>?;
      _config             = _modelo!['config'] as Map<String, dynamic>?;
      _categoriaMapping   = _modelo!['categoria_mapping'] as Map<String, dynamic>?;
      _cargado = true;
    } catch (_) {
      _cargado = false;
    }

    // Cargar hotspots reales generados por Python desde Nominatim
    try {
      final rawH = await rootBundle.loadString(_hotspotsPath);
      _hotspots = (json.decode(rawH) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      _hotspots = [];
    }
  }

  List<double> predecir(MlFeatureVector features) {
    if (!_cargado || _arboles == null) {
      return _heuristicaFallback(features);
    }
    final votos = [0, 0, 0];
    final vals  = features.toList();
    for (final arbol in _arboles!) {
      votos[_predecirArbol(arbol as Map<String, dynamic>, vals)]++;
    }
    final total = votos.reduce((a, b) => a + b);
    return votos.map((v) => v / total).toList();
  }

  int _predecirArbol(Map<String, dynamic> nodo, List<double> features) {
    if (nodo['leaf'] == true) return nodo['class'] as int;
    final idx       = nodo['feature_idx'] as int;
    final threshold = (nodo['threshold'] as num).toDouble();
    return features[idx] <= threshold
        ? _predecirArbol(nodo['left']  as Map<String, dynamic>, features)
        : _predecirArbol(nodo['right'] as Map<String, dynamic>, features);
  }

  int categoriaCodigo(String categoria) {
    if (_categoriaMapping?.containsKey(categoria) == true) {
      return (_categoriaMapping![categoria] as num).toInt();
    }
    const cats = [
      'Invasión vehicular', 'Materiales de construcción',
      'Ocupación comercial', 'Otro',
      'Publicidad no autorizada', 'Venta informal',
    ];
    return cats.indexOf(categoria).clamp(0, cats.length - 1);
  }

  MlFeatureVector construirFeatures({
    required double lat,
    required double lng,
    required String categoriaPredominante,
    required int reportesTotales,
    required int reportes48h,
    required bool esHotspotReciente,
    DateTime? fechaRef,
  }) {
    final fecha   = fechaRef ?? DateTime.now();
    final gridLat = ((lat - 1.20) / 0.003).floor();
    final gridLng = ((lng + 77.31) / 0.003).floor();

    int franja(int h) {
      if (h < 7)  return 0;
      if (h < 12) return 1;
      if (h < 17) return 2;
      if (h < 21) return 3;
      return 4;
    }

    return MlFeatureVector(
      latitud:         lat,
      longitud:        lng,
      categoriaCod:    categoriaCodigo(categoriaPredominante),
      diaSemana:       fecha.weekday - 1,
      mes:             fecha.month,
      franjaHora:      franja(fecha.hour),
      esFinde:         fecha.weekday >= 6 ? 1 : 0,
      densidadGrid:    reportesTotales.toDouble(),
      ventana48h:      reportes48h.toDouble(),
      zonaReincidente: esHotspotReciente ? 1 : 0,
      gridLat:         gridLat,
      gridLng:         gridLng,
    );
  }

  List<ZonaRiesgo> obtenerZonasPrecalculadas() {
    if (_zonasPrecalculadas == null) return [];
    return _zonasPrecalculadas!
        .map((z) => ZonaRiesgo.fromJson(z as Map<String, dynamic>))
        .where((z) => z.reportesHistoricos >= 3)
        .toList();
  }

  List<double> _heuristicaFallback(MlFeatureVector f) {
    double score = 0;
    score += (f.densidadGrid / 40).clamp(0, 1) * 3;
    score += (f.ventana48h   /  8).clamp(0, 1) * 2;
    score += f.zonaReincidente * 1.5;
    score += f.esFinde         * 0.5;
    if (score < 1.5) return [0.75, 0.20, 0.05];
    if (score < 3.0) return [0.15, 0.65, 0.20];
    return [0.05, 0.15, 0.80];
  }
}