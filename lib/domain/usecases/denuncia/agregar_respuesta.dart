import '../../repositories/denuncia_repository.dart';

class AgregarRespuesta {
  final DenunciaRepository repository;

  AgregarRespuesta(this.repository);

  Future<bool> call(int denunciaId, String respuesta) {
    if (respuesta.trim().isEmpty) {
      throw ArgumentError('La respuesta no puede estar vacía');
    }
    return repository.agregarRespuestaOficial(denunciaId, respuesta);
  }
}