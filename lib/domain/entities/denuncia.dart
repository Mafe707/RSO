import 'evidencia.dart';  

class Denuncia {
  final int id;
  final String codigoUnico;
  final String ubicacion;
  final double? latitud;
  final double? longitud;
  final String categoria;
  final String? descripcion;
  final String estado;
  final String? respuestaOficial;
  final String? imagenUrl;
  final String? imagenPath;
  final int? funcionarioId;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<Evidencia> evidencias;

  const Denuncia({
    required this.id,
    required this.codigoUnico,
    required this.ubicacion,
    this.latitud,
    this.longitud,
    required this.categoria,
    this.descripcion,
    required this.estado,
    this.respuestaOficial,
    this.imagenUrl,
    this.imagenPath,
    this.funcionarioId,
    required this.creadoEn,
    required this.actualizadoEn,
    this.evidencias = const [],
  });
}