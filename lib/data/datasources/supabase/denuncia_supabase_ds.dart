import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/codigo_generator.dart';
import '../../models/denuncia_model.dart';

class DenunciaSupabaseDs {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _bucket = 'evidencias';

  Future<DenunciaModel> crearDenuncia({
    required String ubicacion,
    double? latitud,
    double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
  }) async {
    try {
      final codigoUnico = CodigoGenerator.generar();
      final ahora = DateTime.now().toIso8601String();

      String? imagenUrl;
      String? imagenPath;

      // Subir primera imagen principal si existe
      if (imagenesBytes != null && imagenesBytes.isNotEmpty) {
        final nombreArchivo =
            '$codigoUnico-${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagenPath = 'denuncias/$nombreArchivo';

        await _supabase.storage.from(_bucket).uploadBinary(
              imagenPath,
              imagenesBytes.first,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        imagenUrl =
            _supabase.storage.from(_bucket).getPublicUrl(imagenPath);
      }

      final response = await _supabase.from('denuncias').insert({
        'codigo_unico': codigoUnico,
        'ubicacion': ubicacion.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'categoria': categoria.trim(),
        'descripcion': descripcion.trim(),
        'imagen_url': imagenUrl,
        'imagen_path': imagenPath,
        'estado': 'pendiente',
        'creado_en': ahora,
        'actualizado_en': ahora,
      }).select().single();

      final denuncia = DenunciaModel.fromJson(response);

      // Subir imágenes adicionales a tabla evidencias
      if (imagenesBytes != null && imagenesBytes.length > 1) {
        for (int i = 1; i < imagenesBytes.length; i++) {
          final nombre =
              '$codigoUnico-extra$i-${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ruta = 'denuncias/$nombre';

          await _supabase.storage.from(_bucket).uploadBinary(
                ruta,
                imagenesBytes[i],
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );

          final url = _supabase.storage.from(_bucket).getPublicUrl(ruta);

          await _supabase.from('evidencias').insert({
            'denuncia_id': denuncia.id,
            'archivo_url': url,
            'tipo': 'imagen',
          });
        }
      }

      return denuncia;
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<DenunciaModel?> obtenerPorCodigo(String codigo) async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select()
          .eq('codigo_unico', codigo.toUpperCase().trim())
          .maybeSingle();

      if (response == null) return null;
      return DenunciaModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<List<DenunciaModel>> obtenerTodas() async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select()
          .order('creado_en', ascending: false);

      return (response as List)
          .map((e) => DenunciaModel.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<bool> actualizarEstado(int id, String nuevoEstado) async {
    try {
      await _supabase.from('denuncias').update({
        'estado': nuevoEstado,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<bool> asignarFuncionario(int denunciaId, int funcionarioId) async {
    try {
      await _supabase.from('denuncias').update({
        'funcionario_id': funcionarioId,
        'estado': 'en_revision',
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', denunciaId);
      return true;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<bool> agregarRespuestaOficial(int id, String respuesta) async {
    try {
      await _supabase.from('denuncias').update({
        'respuesta_oficial': respuesta.trim(),
        'estado': 'resuelta',
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}