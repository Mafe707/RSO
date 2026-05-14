// Representa un reporte individual, compatible con el esquema real de Supabase.
// Puede construirse desde un Map de Supabase o desde datos sintéticos generados
// en Dart cuando no hay suficientes registros reales.
class ReporteSintetico {
  final int? id;
  final String codigoUnico;
  final String ubicacion;
  final double latitud;
  final double longitud;
  final String categoria;
  final String descripcion;
  final String estado;
  final DateTime creadoEn;
  final bool esSintetico;

  const ReporteSintetico({
    this.id,
    required this.codigoUnico,
    required this.ubicacion,
    required this.latitud,
    required this.longitud,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    required this.creadoEn,
    this.esSintetico = false,
  });

  // Construye desde un Map de Supabase (datos reales)
  factory ReporteSintetico.fromSupabase(Map<String, dynamic> map) {
    return ReporteSintetico(
      id: map['id'] as int?,
      codigoUnico: map['codigo_unico'] as String? ?? '',
      ubicacion: map['ubicacion'] as String? ?? '',
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0.0,
      categoria: map['categoria'] as String? ?? 'Otro',
      descripcion: map['descripcion'] as String? ?? '',
      estado: map['estado'] as String? ?? 'pendiente',
      creadoEn: map['creado_en'] != null
          ? DateTime.tryParse(map['creado_en'].toString()) ?? DateTime.now()
          : DateTime.now(),
      esSintetico: false,
    );
  }

  // Construye desde un Map interno (datos sintéticos en Dart)
  factory ReporteSintetico.fromSintetico(Map<String, dynamic> map) {
    return ReporteSintetico(
      id: null,
      codigoUnico: map['codigo_unico'] as String,
      ubicacion: map['ubicacion'] as String,
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String,
      estado: map['estado'] as String,
      creadoEn: map['creado_en'] as DateTime,
      esSintetico: true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'codigo_unico': codigoUnico,
        'ubicacion': ubicacion,
        'latitud': latitud,
        'longitud': longitud,
        'categoria': categoria,
        'descripcion': descripcion,
        'estado': estado,
        'creado_en': creadoEn.toIso8601String(),
        'es_sintetico': esSintetico,
      };
}