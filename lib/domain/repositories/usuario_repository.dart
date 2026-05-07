import '../entities/usuario.dart';

abstract class UsuarioRepository {
  // Funcionario
  Future<Usuario?> obtenerFuncionarioPorAuthId(String authUserId);
  Future<List<Usuario>> obtenerTodosFuncionarios();
  Future<bool> actualizarFuncionario(int id, Map<String, dynamic> datos);

  // Administrador
  Future<Usuario?> obtenerAdminPorAuthId(String authUserId);
}