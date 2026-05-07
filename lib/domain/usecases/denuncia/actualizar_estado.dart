import '../../repositories/denuncia_repository.dart';

class ActualizarEstado {
  final DenunciaRepository repository;

  ActualizarEstado(this.repository);

  // estados válidos: 'pendiente' | 'en_revision' | 'resuelta'
  Future<bool> call(int denunciaId, String nuevoEstado) {
    const estadosValidos = ['pendiente', 'en_revision', 'resuelta'];

    if (!estadosValidos.contains(nuevoEstado)) {
      throw ArgumentError('Estado no válido: $nuevoEstado');
    }

    return repository.actualizarEstado(denunciaId, nuevoEstado);
  }
}