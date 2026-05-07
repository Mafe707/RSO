import 'dart:typed_data';
import '../../entities/evidencia.dart';
import '../../repositories/evidencia_repository.dart';

class AgregarEvidencia {
  final EvidenciaRepository repository;
  AgregarEvidencia(this.repository);

  Future<Evidencia?> call({
    required int denunciaId,
    required Uint8List archivoBytes,
  }) {
    return repository.agregarEvidencia(
      denunciaId: denunciaId,
      archivoBytes: archivoBytes,
    );
  }
}
