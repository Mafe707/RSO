import '../../entities/denuncia.dart';
import '../../repositories/denuncia_repository.dart';

class ObtenerTodasDenuncias {
  final DenunciaRepository repository;
  ObtenerTodasDenuncias(this.repository);

  Future<List<Denuncia>> call() {
    return repository.obtenerTodas();
  }
}