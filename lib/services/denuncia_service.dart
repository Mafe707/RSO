import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';
import '../core/utils/codigo_generator.dart';

// Modelo para grupo de denuncias con misma ubicación + categoría
class GrupoDenuncias {
  final String claveGrupo;
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

  /// True si es un caso solo (sin agrupación real):
  /// - Siempre que tenga 1 sola denuncia (independientemente de si tiene dirección/categoría)
  /// - O si fue marcado explícitamente como individual por no tener dirección ni categoría
  bool get esIndividual => totalCasos == 1 || claveGrupo.startsWith('individual|');

  String get estadoGrupo {
    final estados = denuncias.map((d) => d['estado']?.toString() ?? '').toList();
    if (estados.any((e) => e == 'devuelto')) return 'devuelto';
    if (estados.any((e) => e == 'en_revision')) return 'en_revision';
    if (estados.any((e) => e == 'resuelto_pendiente_validacion')) {
      return 'resuelto_pendiente_validacion';
    }
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
  static const double _radioAgrupacionMetros = 50;

  static List<GrupoDenuncias> agruparDenuncias(List<Map<String, dynamic>> lista) {
    final List<GrupoDenuncias> grupos = [];

    for (final denuncia in lista) {
      final categoriaNorm = _normalizarCategoria(
        denuncia['categoria']?.toString() ?? '',
      );
      final ubicacionNorm = _normalizarDireccion(
        denuncia['ubicacion']?.toString() ?? '',
      );

      // Si no tiene dirección NI categoría, va siempre sola (grupo individual)
      final esIndividual = ubicacionNorm.isEmpty && categoriaNorm.isEmpty;

      if (esIndividual) {
        grupos.add(
          GrupoDenuncias(
            claveGrupo: 'individual|${denuncia['id']}',
            ubicacion: denuncia['ubicacion']?.toString() ?? '',
            categoria: denuncia['categoria']?.toString() ?? '',
            denuncias: [denuncia],
          ),
        );
        continue;
      }

      final lat = _toDouble(denuncia['latitud']);
      final lng = _toDouble(denuncia['longitud']);

      GrupoDenuncias? grupoEncontrado;

      for (final grupo in grupos) {
        // No agrupar con grupos individuales
        if (grupo.claveGrupo.startsWith('individual|')) continue;

        final categoriaGrupoNorm = _normalizarCategoria(grupo.categoria);
        if (categoriaGrupoNorm != categoriaNorm) continue;

        final ubicacionGrupoNorm = _normalizarDireccion(grupo.ubicacion);

        final coincideTexto = _direccionesParecidas(
          ubicacionNorm,
          ubicacionGrupoNorm,
        );

        bool coincideMapa = false;
        if (lat != null && lng != null) {
          for (final d in grupo.denuncias) {
            final glat = _toDouble(d['latitud']);
            final glng = _toDouble(d['longitud']);
            if (glat != null && glng != null) {
              final distancia = _distanciaMetros(lat, lng, glat, glng);
              if (distancia <= _radioAgrupacionMetros) {
                coincideMapa = true;
                break;
              }
            }
          }
        }

        if (coincideTexto || coincideMapa) {
          grupoEncontrado = grupo;
          break;
        }
      }

      if (grupoEncontrado != null) {
        grupoEncontrado.denuncias.add(denuncia);
      } else {
        grupos.add(
          GrupoDenuncias(
            claveGrupo: '${ubicacionNorm}|$categoriaNorm',
            ubicacion: denuncia['ubicacion']?.toString() ?? '',
            categoria: denuncia['categoria']?.toString() ?? '',
            denuncias: [denuncia],
          ),
        );
      }
    }

    grupos.sort((a, b) => b.totalCasos.compareTo(a.totalCasos));
    return grupos;
  }

  // Cast profundo para respuestas con joins de Supabase
  static List<Map<String, dynamic>> castearLista(dynamic response) {
    return (response as List).map((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
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

  static String _normalizarCategoria(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalizarDireccion(String input) {
    var s = input.toLowerCase().trim();

    s = s
        .replaceAll('carrera', 'cra')
        .replaceAll('cra.', 'cra')
        .replaceAll('cr.', 'cra')
        .replaceAll('cr ', 'cra ')
        .replaceAll('calle', 'cl')
        .replaceAll('cll', 'cl')
        .replaceAll('cl.', 'cl')
        .replaceAll('avenida', 'av')
        .replaceAll('av.', 'av')
        .replaceAll('diagonal', 'dg')
        .replaceAll('diag.', 'dg')
        .replaceAll('transversal', 'tv')
        .replaceAll('transv.', 'tv')
        .replaceAll('trans.', 'tv')
        .replaceAll('#', ' ')
        .replaceAll('-', ' ')
        .replaceAll('.', ' ')
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .replaceAll(':', ' ');

    s = s.replaceAll(RegExp(r'[^a-z0-9áéíóúñ\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static bool _direccionesParecidas(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    final tokensA = a.split(' ').where((e) => e.isNotEmpty).toList();
    final tokensB = b.split(' ').where((e) => e.isNotEmpty).toList();

    final numsA = tokensA.where((t) => RegExp(r'^\d+$').hasMatch(t)).toList();
    final numsB = tokensB.where((t) => RegExp(r'^\d+$').hasMatch(t)).toList();

    final viasA = tokensA.where((t) => !RegExp(r'^\d+$').hasMatch(t)).toList();
    final viasB = tokensB.where((t) => !RegExp(r'^\d+$').hasMatch(t)).toList();

    final mismaVia = viasA.isNotEmpty && viasB.isNotEmpty && viasA.first == viasB.first;

    final numerosCoinciden = numsA.isNotEmpty &&
        numsB.isNotEmpty &&
        _interseccion(numsA, numsB) >= math.min(numsA.length, numsB.length);

    if (mismaVia && numerosCoinciden) return true;

    final coincidencias = _interseccion(tokensA, tokensB);
    final totalMin = math.min(tokensA.length, tokensB.length);
    if (totalMin == 0) return false;

    final ratio = coincidencias / totalMin;
    return ratio >= 0.75;
  }

  static int _interseccion(List<String> a, List<String> b) {
    final setB = b.toSet();
    return a.where(setB.contains).length;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static double _distanciaMetros(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);

  Future<Map<String, dynamic>?> crearDenuncia({
    required String ubicacion,
    double? latitud,
    double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
    required bool esAnonima,
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