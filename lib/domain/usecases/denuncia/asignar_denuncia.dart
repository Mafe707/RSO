import '../../repositories/denuncia_repository.dart';

class AsignarDenuncia {
  final DenunciaRepository repository;

  AsignarDenuncia(this.repository);

  Future<bool> call(int denunciaId, int funcionarioId) {
    return repository.asignarFuncionario(denunciaId, funcionarioId);
  }
}