import 'package:flutter/material.dart';

enum NivelRiesgo { bajo, medio, alto }

class ZonaRiesgo {
  final String gridId;
  final String zonaNombre;
  final double latCentro;
  final double lngCentro;
  final NivelRiesgo nivelRiesgo;
  final double probabilidadAlto;
  final int reportesHistoricos;
  final int reportesUltimas48h;
  final String categoriaPredominante;
  final bool alertaActiva;
  final String? mensajeAlerta;

  const ZonaRiesgo({
    required this.gridId,
    required this.zonaNombre,
    required this.latCentro,
    required this.lngCentro,
    required this.nivelRiesgo,
    required this.probabilidadAlto,
    required this.reportesHistoricos,
    required this.reportesUltimas48h,
    required this.categoriaPredominante,
    required this.alertaActiva,
    this.mensajeAlerta,
  });

  // Nombre de zona SIEMPRE desde el hotspot más cercano, nunca "desconocida"
  static String nombreDesdeCoordenadas(double lat, double lng) {
    const hotspots = [
      (1.2136, -77.2811, 'Centro — Calle 17'),           // Intersección central histórica
      (1.2120, -77.2790, 'Centro — Carrera 23'),          // Intersección centro
      (1.19614, -77.27071, 'Plaza El Potrerillo'),        // Plaza de Mercado Potrerillo [web:169][web:175]
      (1.2090, -77.2830, 'Sector La Panadería'),          // Sector aproximado
      (1.2160, -77.2850, 'Av. Julián Bucheli'),           // Corredor vial central
      (1.2200, -77.2920, 'Barrio Las Lunas'),             // Barrio confirmado [web:181]
      (1.2250, -77.2780, 'Bomboná'),                      // Barrio Comuna 1 [web:165]
      (1.2070, -77.2760, 'San Andrés'),                   // Barrio Comuna 1 [web:165]
      (1.2180, -77.2700, 'El Ejido'),                     // Barrio confirmado [web:181]
      (1.2300, -77.2850, 'Rumipamba'),                    // Barrio confirmado [web:181]
      (1.2350, -77.2900, 'La Rosa'),                      // Barrio confirmado [web:181]
      (1.2220, -77.2650, 'Tamasagra'),                    // Barrio confirmado [web:167][web:168]
      (1.2400, -77.2950, 'Torobajo'),                     // Corregimiento/barrio
      (1.2280, -77.2820, 'Las Cuadras — Parque Infantil'), // Punto de referencia
      (1.20461, -77.29179, 'Mijitayo'),                   // Barrio confirmado [web:173][web:176]
      (1.2330, -77.2880, 'Aranda'),                       // Barrio Comuna 8 [web:181]
    ];
    double minDist = double.infinity;
    String nombre = 'Centro — Calle 17';
    for (final hs in hotspots) {
      final dLat = lat - hs.$1;
      final dLng = lng - hs.$2;
      final d = dLat * dLat + dLng * dLng;
      if (d < minDist) {
        minDist = d;
        nombre = hs.$3;
      }
    }
    return nombre;
  }

  factory ZonaRiesgo.fromJson(Map<String, dynamic> json) {
    final nivelStr = json['nivel_riesgo'] as String? ?? 'bajo';
    final nivel = nivelStr == 'alto'
        ? NivelRiesgo.alto
        : nivelStr == 'medio'
            ? NivelRiesgo.medio
            : NivelRiesgo.bajo;

    final probs = (json['probabilidades'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [1.0, 0.0, 0.0];
    final probAlto = probs.length >= 3 ? probs[2] : 0.0;
    final n48h = json['reportes_48h'] as int? ?? 0;

    bool alerta = false;
    String? mensaje;
    if (n48h >= 8) {
      alerta = true;
      mensaje = '⚠️ Incremento crítico: $n48h reportes en 48h — intervención urgente';
    } else if (n48h >= 5) {
      alerta = true;
      mensaje = '📍 Actividad inusual: $n48h reportes en las últimas 48 horas';
    }

    final latC = (json['lat_centro'] as num?)?.toDouble() ?? 1.2136;
    final lngC = (json['lng_centro'] as num?)?.toDouble() ?? -77.2811;

    // Nombre: primero del JSON (generado por Python), si falla usa coordenadas
    String nombre = json['zona_nombre'] as String? ?? '';
    if (nombre.isEmpty || nombre == 'Zona desconocida') {
      nombre = nombreDesdeCoordenadas(latC, lngC);
    }

    return ZonaRiesgo(
      gridId: json['grid_id'] as String? ?? '',
      zonaNombre: nombre,
      latCentro: latC,
      lngCentro: lngC,
      nivelRiesgo: nivel,
      probabilidadAlto: probAlto,
      reportesHistoricos: json['reportes_historicos'] as int? ?? 0,
      reportesUltimas48h: n48h,
      categoriaPredominante: json['categoria_predominante'] as String? ?? 'Venta informal',
      alertaActiva: alerta,
      mensajeAlerta: mensaje,
    );
  }

  Color get colorRiesgo {
    switch (nivelRiesgo) {
      case NivelRiesgo.alto:  return const Color(0xFFD32F2F);
      case NivelRiesgo.medio: return const Color(0xFFF57C00);
      case NivelRiesgo.bajo:  return const Color(0xFF388E3C);
    }
  }

  String get labelRiesgo {
    switch (nivelRiesgo) {
      case NivelRiesgo.alto:  return 'Alto';
      case NivelRiesgo.medio: return 'Medio';
      case NivelRiesgo.bajo:  return 'Bajo';
    }
  }

  IconData get iconoCategoria {
    switch (categoriaPredominante) {
      case 'Venta informal':            return Icons.shopping_bag_outlined;
      case 'Invasión vehicular':        return Icons.directions_car_outlined;
      case 'Ocupación comercial':       return Icons.store_outlined;
      case 'Publicidad no autorizada':  return Icons.campaign_outlined;
      case 'Materiales de construcción': return Icons.construction_outlined;
      default:                          return Icons.warning_amber_outlined;
    }
  }

  String get porcentaje => '${(probabilidadAlto * 100).toStringAsFixed(0)}%';
}