// Vector de features que el modelo Random Forest usa para predecir.
// Los nombres deben coincidir exactamente con los del script Python.
class MlFeatureVector {
  final double latitud;
  final double longitud;
  final int categoriaCod;
  final int diaSemana;      // 0=lunes ... 6=domingo
  final int mes;            // 1-12
  final int franjaHora;     // 0=noche, 1=mañana, 2=tarde, 3=noche2, 4=madrugada
  final int esFinde;        // 0 o 1
  final double densidadGrid;
  final double ventana48h;
  final int zonaReincidente; // 0 o 1
  final int gridLat;
  final int gridLng;

  const MlFeatureVector({
    required this.latitud,
    required this.longitud,
    required this.categoriaCod,
    required this.diaSemana,
    required this.mes,
    required this.franjaHora,
    required this.esFinde,
    required this.densidadGrid,
    required this.ventana48h,
    required this.zonaReincidente,
    required this.gridLat,
    required this.gridLng,
  });

  // Convierte a lista ordenada igual que Python
  List<double> toList() => [
        latitud,
        longitud,
        categoriaCod.toDouble(),
        diaSemana.toDouble(),
        mes.toDouble(),
        franjaHora.toDouble(),
        esFinde.toDouble(),
        densidadGrid,
        ventana48h,
        zonaReincidente.toDouble(),
        gridLat.toDouble(),
        gridLng.toDouble(),
      ];

  static const List<String> featureNames = [
    'latitud',
    'longitud',
    'categoria_cod',
    'dia_semana',
    'mes',
    'franja_hora',
    'es_finde',
    'densidad_grid',
    'ventana_48h',
    'zona_reincidente',
    'grid_lat',
    'grid_lng',
  ];
}