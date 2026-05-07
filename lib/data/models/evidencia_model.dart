import '../../domain/entities/evidencia.dart';

class EvidenciaModel extends Evidencia {
  const EvidenciaModel({
    required super.id,
    required super.denunciaId,
    super.archivoUrl,
    required super.tipo,
    required super.subidoEn,
  });

  factory EvidenciaModel.fromJson(Map<String, dynamic> json) {
    return EvidenciaModel(
      id: json['id'] as int,
      denunciaId: json['denuncia_id'] as int,
      archivoUrl: json['archivo_url'] as String?,
      tipo: json['tipo'] as String? ?? 'imagen',
      subidoEn: DateTime.parse(json['subido_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'denuncia_id': denunciaId,
      'archivo_url': archivoUrl,
      'tipo': tipo,
    };
  }
}