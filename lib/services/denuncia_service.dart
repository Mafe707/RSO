import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../core/utils/codigo_generator.dart';

class DenunciaService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _denuncias = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get denuncias => _denuncias;
  bool get isLoading => _isLoading;

  static const String _bucketEvidencias = 'evidencias';
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  Future<Map<String, dynamic>?> crearDenuncia({
    required String ubicacion,
    required double? latitud,
    required double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
  }) async {
    _setLoading(true);

    try {
      if (ubicacion.trim().isEmpty) {
        throw Exception('La ubicación es requerida');
      }
      if (categoria.trim().isEmpty) {
        throw Exception('La categoría es requerida');
      }
      if (descripcion.trim().isEmpty) {
        throw Exception('La descripción es requerida');
      }

      if (imagenesBytes != null) {
        for (int i = 0; i < imagenesBytes.length; i++) {
          if (imagenesBytes[i].length > _maxSizeBytes) {
            throw Exception('La imagen ${i + 1} supera los 5MB');
          }
        }
      }

      final codigoUnico = CodigoGenerator.generar();
      final fechaActual = DateTime.now().toIso8601String();

      String? imagenUrl;
      String? imagenPath;

      if (imagenesBytes != null && imagenesBytes.isNotEmpty) {
        final nombreArchivo =
            '$codigoUnico-${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagenPath = 'denuncias/$nombreArchivo';

        await _supabase.storage.from(_bucketEvidencias).uploadBinary(
              imagenPath,
              imagenesBytes.first,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        imagenUrl = _supabase.storage
            .from(_bucketEvidencias)
            .getPublicUrl(imagenPath);
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
        'creado_en': fechaActual,
        'actualizado_en': fechaActual,
      }).select().single();

      final nuevaDenuncia = Map<String, dynamic>.from(response);
      final denunciaId = nuevaDenuncia['id'] as int;

      if (imagenesBytes != null && imagenesBytes.length > 1) {
        for (int i = 1; i < imagenesBytes.length; i++) {
          final nombre =
              '$codigoUnico-extra$i-${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ruta = 'denuncias/$nombre';

          await _supabase.storage.from(_bucketEvidencias).uploadBinary(
                ruta,
                imagenesBytes[i],
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                ),
              );

          final url =
              _supabase.storage.from(_bucketEvidencias).getPublicUrl(ruta);

          await _supabase.from('evidencias').insert({
            'denuncia_id': denunciaId,
            'archivo_url': url,
            'tipo': 'imagen',
          });
        }
      }

      _denuncias.insert(0, nuevaDenuncia);
      notifyListeners();

      return nuevaDenuncia;
    } catch (e) {
      debugPrint('Error al crear denuncia: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> obtenerDenunciaPorCodigo(String codigo) async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select('''
            *,
            evidencias (
              id,
              archivo_url,
              tipo
            )
          ''')
          .eq('codigo_unico', codigo.toUpperCase().trim())
          .maybeSingle();

      if (response == null) return null;

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener denuncia por código: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTodasDenuncias() async {
    _setLoading(true);

    try {
      final response = await _supabase
          .from('denuncias')
          .select()
          .order('creado_en', ascending: false);

      _denuncias = List<Map<String, dynamic>>.from(response);
      notifyListeners();
      return _denuncias;
    } catch (e) {
      debugPrint('Error al obtener denuncias: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarEstado(int id, String nuevoEstado) async {
    try {
      await _supabase.from('denuncias').update({
        'estado': nuevoEstado,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoConRespuesta(
    int id,
    String nuevoEstado,
    String respuesta,
  ) async {
    try {
      final Map<String, dynamic> data = {
        'estado': nuevoEstado,
        'actualizado_en': DateTime.now().toIso8601String(),
      };

      if (respuesta.isNotEmpty) {
        data['respuesta_oficial'] = respuesta;
      }

      await _supabase.from('denuncias').update(data).eq('id', id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado con respuesta: $e');
      return false;
    }
  }

  Future<bool> asignarFuncionario(int denunciaId, int funcionarioId) async {
    try {
      await _supabase.from('denuncias').update({
        'funcionario_id': funcionarioId,
        'estado': 'en_revision',
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', denunciaId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al asignar funcionario: $e');
      return false;
    }
  }

  Future<bool> agregarRespuestaOficial(int id, String respuesta) async {
    try {
      await _supabase.from('denuncias').update({
        'respuesta_oficial': respuesta.trim(),
        'estado': 'resuelto_pendiente_validacion',
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al agregar respuesta: $e');
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}