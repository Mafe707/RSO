import '../../entities/usuario.dart';
import '../../repositories/usuario_repository.dart';

class ObtenerFuncionarios {
  final UsuarioRepository repository;

  ObtenerFuncionarios(this.repository);

  Future<List<Usuario>> call() {
    return repository.obtenerTodosFuncionarios();
  }
}