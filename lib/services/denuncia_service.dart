import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';
import '../core/utils/codigo_generator.dart';

// Modelo para grupo de denuncias con misma ubicación + categoría
class GrupoDenuncias {
  final String claveGrupo; // ubicacion|categoria
  final String ubicacion;
  final String categoria;
  final List<Map<String, dynamic>> denuncias;

  GrupoDenuncias({
    required this.claveGrupo,
    required this.ubicacion,
    required this.categoria,
    required this.denuncias,
  });

  int get totalCasos => denuncias.length;

  // Estado del grupo: el peor estado de todos
  String get estadoGrupo {
    final estados = denuncias.map((d) => d['estado']?.toString() ?? '').toList();
    if (estados.any((e) => e == 'devuelto')) return 'devuelto';
    if (estados.any((e) => e == 'en_revision')) return 'en_revision';
    if (estados.any((e) => e == 'resuelto_pendiente_validacion')) return 'resuelto_pendiente_validacion';
    if (estados.any((e) => e == 'resuelto_publicado')) return 'resuelto_publicado';
    return 'pendiente';
  }

  List<int> get ids => denuncias.map((d) => d['id'] as int).toList();
  List<String> get codigos => denuncias.map((d) => d['codigo_unico']?.toString() ?? '').toList();
}

class DenunciaService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _denuncias = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get denuncias => _denuncias;
  bool get isLoading => _isLoading;

  static const String _bucketEvidencias = 'evidencias';
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  // Agrupa denuncias por ubicacion + categoria (misma invasión)
  static List<GrupoDenuncias> agruparDenuncias(List<Map<String, dynamic>> lista) {
    final Map<String, List<Map<String, dynamic>>> mapa = {};
    for (final d in lista) {
      final ubicacion = (d['ubicacion']?.toString() ?? '').trim().toLowerCase();
      final categoria = (d['categoria']?.toString() ?? '').trim().toLowerCase();
      final clave = '$ubicacion|$categoria';
      mapa.putIfAbsent(clave, () => []);
      mapa[clave]!.add(d);
    }
    return mapa.entries.map((entry) {
      final primera = entry.value.first;
      return GrupoDenuncias(
        claveGrupo: entry.key,
        ubicacion: primera['ubicacion']?.toString() ?? '',
        categoria: primera['categoria']?.toString() ?? '',
        denuncias: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.totalCasos.compareTo(a.totalCasos));
  }

  // Cast profundo para respuestas con joins de Supabase
  static List<Map<String, dynamic>> castearLista(dynamic response) {
    return (response as List).map((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
      // Cast profundo de listas anidadas (evidencias, etc.)
      mapa.forEach((key, value) {
        if (value is List) {
          mapa[key] = value
              .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : e)
              .toList();
        }
      });
      return mapa;
    }).toList();
  }

  Future<Map<String, dynamic>?> crearDenuncia({
    required String ubicacion,
    required double? latitud,
    required double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
    bool esAnonima = true,
    int? ciudadanoId,
    String? ciudadanoNombre,
    String? ciudadanoApellido,
    String? ciudadanoCorreo,
    String? ciudadanoTelefono,
  }) async {
    _setLoading(true);
    try {
      if (ubicacion.trim().isEmpty) throw Exception('La ubicación es requerida');
      if (categoria.trim().isEmpty) throw Exception('La categoría es requerida');
      if (descripcion.trim().isEmpty) throw Exception('La descripción es requerida');

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
        final nombreArchivo = '$codigoUnico-${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagenPath = 'denuncias/$nombreArchivo';
        await _supabase.storage.from(_bucketEvidencias).uploadBinary(
          imagenPath,
          imagenesBytes.first,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
        imagenUrl = _supabase.storage.from(_bucketEvidencias).getPublicUrl(imagenPath);
      }

      final Map<String, dynamic> payload = {
        'codigo_unico': codigoUnico,
        'ubicacion': ubicacion.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'categoria': categoria.trim(),
        'descripcion': descripcion.trim(),
        'imagen_url': imagenUrl,
        'imagen_path': imagenPath,
        'estado': 'pendiente',
        'es_anonima': esAnonima,
        'creado_en': fechaActual,
        'actualizado_en': fechaActual,
      };

      if (!esAnonima) {
        payload['ciudadano_id'] = ciudadanoId;
        payload['ciudadano_nombre'] = ciudadanoNombre;
        payload['ciudadano_apellido'] = ciudadanoApellido;
        payload['ciudadano_correo'] = ciudadanoCorreo;
        payload['ciudadano_telefono'] = ciudadanoTelefono;
      }

      final response = await _supabase.from('denuncias').insert(payload).select().single();
      final nuevaDenuncia = Map<String, dynamic>.from(response);
      final denunciaId = nuevaDenuncia['id'] as int;

      if (imagenesBytes != null && imagenesBytes.length > 1) {
        for (int i = 1; i < imagenesBytes.length; i++) {
          final nombre = '$codigoUnico-extra$i-${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ruta = 'denuncias/$nombre';
          await _supabase.storage.from(_bucketEvidencias).uploadBinary(
            ruta,
            imagenesBytes[i],
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          final url = _supabase.storage.from(_bucketEvidencias).getPublicUrl(ruta);
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
          .select('*, evidencias(id, archivo_url, tipo)')
          .eq('codigo_unico', codigo.toUpperCase().trim())
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener denuncia: $e');
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

  // Actualiza estado para todos los IDs de un grupo
  Future<bool> actualizarEstadoGrupo(List<int> ids, String nuevoEstado) async {
    try {
      for (final id in ids) {
        await _supabase.from('denuncias').update({
          'estado': nuevoEstado,
          'actualizado_en': DateTime.now().toIso8601String(),
        }).eq('id', id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado de grupo: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoConRespuesta(int id, String nuevoEstado, String respuesta) async {
    try {
      final Map<String, dynamic> data = {
        'estado': nuevoEstado,
        'actualizado_en': DateTime.now().toIso8601String(),
      };
      if (respuesta.isNotEmpty) data['respuesta_oficial'] = respuesta;
      await _supabase.from('denuncias').update(data).eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado con respuesta: $e');
      return false;
    }
  }

  // Agrega respuesta oficial para todos los IDs de un grupo
  Future<bool> agregarRespuestaOficialGrupo(List<int> ids, String respuesta) async {
    try {
      for (final id in ids) {
        await _supabase.from('denuncias').update({
          'respuesta_oficial': respuesta.trim(),
          'estado': 'resuelto_pendiente_validacion',
          'actualizado_en': DateTime.now().toIso8601String(),
        }).eq('id', id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al agregar respuesta de grupo: $e');
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

  // Asigna funcionario a todo el grupo
  Future<bool> asignarFuncionarioGrupo(List<int> ids, int funcionarioId) async {
    try {
      for (final id in ids) {
        await _supabase.from('denuncias').update({
          'funcionario_id': funcionarioId,
          'estado': 'en_revision',
          'actualizado_en': DateTime.now().toIso8601String(),
        }).eq('id', id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al asignar funcionario al grupo: $e');
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