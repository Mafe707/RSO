import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../models/usuario_model.dart';

class UsuarioSupabaseDs {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<UsuarioModel?> obtenerFuncionarioPorAuthId(String authUserId) async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (response == null) return null;
      return UsuarioModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<UsuarioModel?> obtenerAdminPorAuthId(String authUserId) async {
    try {
      final response = await _supabase
          .from('administradores')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (response == null) return null;
      return UsuarioModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<List<UsuarioModel>> obtenerTodosFuncionarios() async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select()
          .eq('activo', true)
          .order('nombre', ascending: true);

      return (response as List)
          .map((e) => UsuarioModel.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<bool> actualizarFuncionario(
      int id, Map<String, dynamic> datos) async {
    try {
      await _supabase
          .from('funcionarios')
          .update({...datos, 'actualizado_en': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}