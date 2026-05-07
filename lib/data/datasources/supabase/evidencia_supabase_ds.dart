import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../models/evidencia_model.dart';

class EvidenciaSupabaseDs {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _bucket = 'evidencias';

  Future<List<EvidenciaModel>> obtenerPorDenuncia(int denunciaId) async {
    try {
      final response = await _supabase
          .from('evidencias')
          .select()
          .eq('denuncia_id', denunciaId)
          .order('subido_en', ascending: true);

      return (response as List)
          .map((e) => EvidenciaModel.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<EvidenciaModel> agregarEvidencia({
    required int denunciaId,
    required Uint8List archivoBytes,
    String tipo = 'imagen',
  }) async {
    try {
      final nombre =
          'extra-$denunciaId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ruta = 'denuncias/$nombre';

      await _supabase.storage.from(_bucket).uploadBinary(
            ruta,
            archivoBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = _supabase.storage.from(_bucket).getPublicUrl(ruta);

      final response = await _supabase.from('evidencias').insert({
        'denuncia_id': denunciaId,
        'archivo_url': url,
        'tipo': tipo,
      }).select().single();

      return EvidenciaModel.fromJson(response);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<bool> eliminarEvidencia(int evidenciaId) async {
    try {
      await _supabase.from('evidencias').delete().eq('id', evidenciaId);
      return true;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}