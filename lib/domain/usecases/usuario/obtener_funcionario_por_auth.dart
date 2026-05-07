import '../../entities/usuario.dart';
import '../../repositories/usuario_repository.dart';

class ObtenerFuncionarioPorAuth {
  final UsuarioRepository repository;

  ObtenerFuncionarioPorAuth(this.repository);

  Future<Usuario?> call(String authUserId) {
    return repository.obtenerFuncionarioPorAuthId(authUserId);
  }
}