import '../../entities/denuncia.dart';
import '../../repositories/denuncia_repository.dart';

class ConsultarDenuncia {
  final DenunciaRepository repository;

  ConsultarDenuncia(this.repository);

  Future<Denuncia?> call(String codigo) {
    return repository.obtenerPorCodigo(codigo);
  }
}