import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  // Estado de autenticación
  Map<String, dynamic>? _currentUser;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Registrar funcionario (Mock)
  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
    required String cargo,
    required String departamento,
  }) async {
    try {
      // Validaciones de negocio
      if (nombre.isEmpty) throw Exception('El nombre es requerido');
      if (email.isEmpty) throw Exception('El correo es requerido');
      if (password.isEmpty) throw Exception('La contraseña es requerida');
      if (cargo.isEmpty) throw Exception('El cargo es requerido');
      if (departamento.isEmpty) throw Exception('El departamento es requerido');
      
      // Validar formato de email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        throw Exception('Ingrese un correo electrónico válido');
      }
      
      // Validar correo institucional @alcaldia.gov.co
      if (!email.toLowerCase().endsWith('@alcaldia.gov.co')) {
        throw Exception('Debe usar su correo institucional (@alcaldia.gov.co)');
      }
      
      // Validar contraseña
      if (password.length < 8) {
        throw Exception('La contraseña debe tener al menos 8 caracteres');
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        throw Exception('La contraseña debe tener al menos una letra mayúscula');
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        throw Exception('La contraseña debe tener al menos un número');
      }
      
      // Simular registro exitoso
      await Future.delayed(const Duration(seconds: 1));
      
      // Verificar si el email ya existe (mock)
      if (email == 'funcionario@alcaldia.gov.co') {
        throw Exception('Este correo ya está registrado');
      }
      
      _currentUser = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'nombre': nombre,
        'email': email,
        'cargo': cargo,
        'departamento': departamento,
        'rol': 'funcionario',
      };
      _isLoggedIn = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Login de funcionario (Mock)
  Future<bool> login(String email, String password) async {
    try {
      // Validaciones
      if (email.isEmpty) throw Exception('El correo es requerido');
      if (password.isEmpty) throw Exception('La contraseña es requerida');
      
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        throw Exception('Ingrese un correo electrónico válido');
      }
      
      if (!email.toLowerCase().endsWith('@alcaldia.gov.co')) {
        throw Exception('Debe usar su correo institucional (@alcaldia.gov.co)');
      }
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Credenciales mock válidas
      final credencialesValidas = {
        'funcionario@alcaldia.gov.co': '123456',
        'maria@alcaldia.gov.co': '123456',
        'javier@alcaldia.gov.co': '123456',
      };
      
      if (credencialesValidas.containsKey(email.toLowerCase()) && 
          credencialesValidas[email.toLowerCase()] == password) {
        
        _currentUser = {
          'id': '1',
          'nombre': email.toLowerCase() == 'funcionario@alcaldia.gov.co' 
              ? 'Carlos Rodríguez' 
              : email.toLowerCase() == 'maria@alcaldia.gov.co'
                  ? 'María González'
                  : 'Javier López',
          'email': email,
          'cargo': 'Inspector de Espacio Público',
          'departamento': 'Espacio Público',
          'rol': 'funcionario',
        };
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Login de administrador (Mock)
  Future<bool> loginAdmin(String email, String password) async {
    try {
      if (email.isEmpty) throw Exception('El correo es requerido');
      if (password.isEmpty) throw Exception('La contraseña es requerida');
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (email == 'admin@alcaldia.gov.co' && password == 'admin123') {
        _currentUser = {
          'id': 'admin_1',
          'nombre': 'Administrador',
          'email': email,
          'rol': 'administrador',
        };
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}