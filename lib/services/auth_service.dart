import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  final _supabase = SupabaseConfig.client;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthService() {
    _checkSession();
  }
  
  Future<void> _checkSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = session.user;
      notifyListeners();
    }
  }
  
  // REGISTRO DE FUNCIONARIO
  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
    required String cargo,
    required String departamento,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 1. Registrar en Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'cargo': cargo,
          'departamento': departamento,
        },
      );
      
      if (authResponse.user == null) {
        throw Exception('Error al registrar');
      }
      
      // 2. Guardar en tabla funcionarios
      await _supabase.from('funcionarios').insert({
        'nombre': nombre,
        'correo': email,
        'contrasena': password,
        'cargo': cargo,
        'departamento': departamento,
        'activo': true,
      });
      
      _currentUser = authResponse.user;
      notifyListeners();
      return true;
      
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // LOGIN
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Credenciales incorrectas');
      }
      
      _currentUser = response.user;
      notifyListeners();
      return true;
      
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}