import 'dart:io';
import 'package:flutter/material.dart';

class DenunciaService extends ChangeNotifier {
  List<Map<String, dynamic>> _denuncias = [];
  
  List<Map<String, dynamic>> get denuncias => _denuncias;

  // Generar código único para la denuncia
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

  // Crear nueva denuncia (Mock)
  Future<Map<String, dynamic>> crearDenuncia({
    required String ubicacion,
    required String categoria,
    required String descripcion,
    required File imagen,
  }) async {
    try {
      // ========== VALIDACIONES FRONTEND ==========
      if (ubicacion.trim().isEmpty) {
        throw Exception('La ubicación es requerida');
      }
      if (categoria.isEmpty) {
        throw Exception('La categoría es requerida');
      }
      if (descripcion.trim().isEmpty) {
        throw Exception('La descripción es requerida');
      }
      if (imagen == null) {
        throw Exception('La evidencia fotográfica es requerida');
      }
      
      // Validar tamaño de imagen (máx 5MB)
      final bytes = await imagen.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        throw Exception('La imagen no debe superar los 5MB');
      }
      
      // Simular envío a Supabase
      await Future.delayed(const Duration(seconds: 2));
      
      final codigoUnico = _generarCodigoUnico();
      final fechaActual = DateTime.now();
      
      final nuevaDenuncia = {
        'id': fechaActual.millisecondsSinceEpoch.toString(),
        'codigo_unico': codigoUnico,
        'ubicacion': ubicacion,
        'categoria': categoria,
        'descripcion': descripcion,
        'estado': 'pendiente',
        'creado_en': fechaActual.toIso8601String(),
        'respuesta_oficial': null,
      };
      
      _denuncias.insert(0, nuevaDenuncia);
      notifyListeners();
      
      return nuevaDenuncia;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener denuncia por código único (Mock)
  Future<Map<String, dynamic>?> obtenerDenunciaPorCodigo(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock de denuncias para consulta
    final mockDenuncias = {
      'PSJ-8A4B2C9D': {
        'codigo_unico': 'PSJ-8A4B2C9D',
        'ubicacion': 'Cra 25 #18-35, Centro, San Juan de Pasto',
        'categoria': 'Venta informal',
        'descripcion': 'Vendedores informales obstruyen el paso peatonal con puestos de comida.',
        'estado': 'revision',
        'creado_en': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'respuesta_oficial': 'El caso ha sido asignado a un inspector municipal para su verificación y gestión.',
      },
      'PSJ-123ABC': {
        'codigo_unico': 'PSJ-123ABC',
        'ubicacion': 'Calle 19 #24-50, Barrio La Enerría',
        'categoria': 'Invasión vehicular',
        'descripcion': 'Vehículo abandonado obstruyendo la acera.',
        'estado': 'pendiente',
        'creado_en': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'respuesta_oficial': null,
      },
      'PSJ-456DEF': {
        'codigo_unico': 'PSJ-456DEF',
        'ubicacion': 'Av. Los Estudiantes #12-08',
        'categoria': 'Ocupación comercial',
        'descripcion': 'Restaurante ocupa parte de la vía pública con mesas.',
        'estado': 'resuelta',
        'creado_en': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'respuesta_oficial': 'Se realizó visita de inspección y se notificó al propietario.',
      },
    };
    
    if (mockDenuncias.containsKey(codigo.toUpperCase())) {
      return mockDenuncias[codigo.toUpperCase()];
    }
    return null;
  }

  // Obtener todas las denuncias (Mock)
  Future<List<Map<String, dynamic>>> obtenerTodasDenuncias() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'id': '1',
        'codigo_unico': 'PSJ-8A4B2C9D',
        'ubicacion': 'Cra 25 #18-35, Centro',
        'categoria': 'Venta informal',
        'estado': 'revision',
        'latitud': 1.2136,
        'longitud': -77.2811,
      },
      {
        'id': '2',
        'codigo_unico': 'PSJ-123ABC',
        'ubicacion': 'Calle 19 #24-50',
        'categoria': 'Invasión vehicular',
        'estado': 'pendiente',
        'latitud': 1.2180,
        'longitud': -77.2780,
      },
      {
        'id': '3',
        'codigo_unico': 'PSJ-456DEF',
        'ubicacion': 'Av. Los Estudiantes',
        'categoria': 'Ocupación comercial',
        'estado': 'resuelta',
        'latitud': 1.2080,
        'longitud': -77.2850,
      },
    ];
  }
}