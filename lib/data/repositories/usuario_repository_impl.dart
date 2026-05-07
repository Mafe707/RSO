import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/supabase/usuario_supabase_ds.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioSupabaseDs _ds;

  UsuarioRepositoryImpl(this._ds);

  @override
  Future<Usuario?> obtenerFuncionarioPorAuthId(String authUserId) =>
      _ds.obtenerFuncionarioPorAuthId(authUserId);

  @override
  Future<Usuario?> obtenerAdminPorAuthId(String authUserId) =>
      _ds.obtenerAdminPorAuthId(authUserId);

  @override
  Future<List<Usuario>> obtenerTodosFuncionarios() =>
      _ds.obtenerTodosFuncionarios();

  @override
  Future<bool> actualizarFuncionario(int id, Map<String, dynamic> datos) =>
      _ds.actualizarFuncionario(id, datos);
}