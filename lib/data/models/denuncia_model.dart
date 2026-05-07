import '../../domain/entities/denuncia.dart';
import 'evidencia_model.dart';

class DenunciaModel extends Denuncia {
  const DenunciaModel({
    required super.id,
    required super.codigoUnico,
    required super.ubicacion,
    super.latitud,
    super.longitud,
    required super.categoria,
    super.descripcion,
    required super.estado,
    super.respuestaOficial,
    super.imagenUrl,
    super.imagenPath,
    super.funcionarioId,
    required super.creadoEn,
    required super.actualizadoEn,
    super.evidencias = const [],
  });

  factory DenunciaModel.fromJson(Map<String, dynamic> json) {
    return DenunciaModel(
      id: json['id'] as int,
      codigoUnico: json['codigo_unico'] as String,
      ubicacion: json['ubicacion'] as String,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'pendiente',
      respuestaOficial: json['respuesta_oficial'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      imagenPath: json['imagen_path'] as String?,
      funcionarioId: json['funcionario_id'] as int?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
      evidencias: (json['evidencias'] as List<dynamic>?)
              ?.map((e) => EvidenciaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_unico': codigoUnico,
      'ubicacion': ubicacion,
      'latitud': latitud,
      'longitud': longitud,
      'categoria': categoria,
      'descripcion': descripcion,
      'estado': estado,
      'respuesta_oficial': respuestaOficial,
      'imagen_url': imagenUrl,
      'imagen_path': imagenPath,
      'funcionario_id': funcionarioId,
    };
  }
}