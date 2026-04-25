import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class DenunciaService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _denuncias = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get denuncias => _denuncias;
  bool get isLoading => _isLoading;

  static const String _bucketEvidencias = 'evidencias';

  // Generar código único
  String _generarCodigoUnico() {
    const prefix = 'PSJ';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    String code = '';
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < 8; i++) {
      code += chars[(now + i) % chars.length];
    }

    return '$prefix-$code';
  }

  // Crear denuncia con imagen
  Future<Map<String, dynamic>?> crearDenuncia({
    required String ubicacion,
    required double? latitud,
    required double? longitud,
    required String categoria,
    required String descripcion,
    required Uint8List imagenBytes,
  }) async {
    _setLoading(true);

    try {
      // Validaciones
      if (ubicacion.trim().isEmpty) {
        throw Exception('La ubicación es requerida');
      }

      if (categoria.trim().isEmpty) {
        throw Exception('La categoría es requerida');
      }

      if (descripcion.trim().isEmpty) {
        throw Exception('La descripción es requerida');
      }

      if (imagenBytes.isEmpty) {
        throw Exception('La imagen es requerida');
      }

      const maxSizeInBytes = 5 * 1024 * 1024;

      if (imagenBytes.length > maxSizeInBytes) {
        throw Exception('La imagen no puede superar los 5MB');
      }

      final codigoUnico = _generarCodigoUnico();
      final fechaActual = DateTime.now().toIso8601String();

      // Ruta de la imagen dentro del bucket
      final nombreArchivo = '$codigoUnico-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rutaImagen = 'denuncias/$nombreArchivo';

      // Subir imagen a Supabase Storage
      await _supabase.storage.from(_bucketEvidencias).uploadBinary(
            rutaImagen,
            imagenBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Obtener URL pública de la imagen
      final imagenUrl = _supabase.storage
          .from(_bucketEvidencias)
          .getPublicUrl(rutaImagen);

      // Guardar denuncia en la tabla
      final response = await _supabase.from('denuncias').insert({
        'codigo_unico': codigoUnico,
        'ubicacion': ubicacion.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'categoria': categoria.trim(),
        'descripcion': descripcion.trim(),
        'imagen_url': imagenUrl,
        'estado': 'pendiente',
        'creado_en': fechaActual,
        'actualizado_en': fechaActual,
      }).select().single();

      final nuevaDenuncia = Map<String, dynamic>.from(response);

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

  // Obtener denuncia por código
  Future<Map<String, dynamic>?> obtenerDenunciaPorCodigo(String codigo) async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select()
          .eq('codigo_unico', codigo.toUpperCase().trim())
          .maybeSingle();

      if (response == null) return null;

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener denuncia por código: $e');
      return null;
    }
  }

  // Obtener todas las denuncias
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}