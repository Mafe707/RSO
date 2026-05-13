import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

class CiudadanoAuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? _currentUser;
  Map<String, dynamic>? _ciudadanoData;
  bool _isLoading = false;
  String? _error;
  bool _sessionChecked = false;

  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get ciudadanoData => _ciudadanoData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get sessionChecked => _sessionChecked;

  CiudadanoAuthService() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _checkSession();
    _sessionChecked = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkSession() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        _currentUser = null;
        _ciudadanoData = null;
        return;
      }

      final user = session.user;
      final ciudadano = await _buscarCiudadanoPorUserId(user.id);

      if (ciudadano == null) {
        await _supabase.auth.signOut();
        _currentUser = null;
        _ciudadanoData = null;
        return;
      }

      _currentUser = user;
      _ciudadanoData = ciudadano;
    } catch (e) {
      debugPrint('Error revisando sesión ciudadano: $e');
      _currentUser = null;
      _ciudadanoData = null;
    }
  }

  Future<Map<String, dynamic>?> _buscarCiudadanoPorUserId(String userId) async {
    try {
      final response = await _supabase
          .from('ciudadanos')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error buscando ciudadano: $e');
      return null;
    }
  }

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String barrio,
    String? fotoUrl,
    String? fotoPath,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final emailNorm = email.trim().toLowerCase();

      final authResponse = await _supabase.auth.signUp(
        email: emailNorm,
        password: password,
        data: {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'rol': 'ciudadano',
        },
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Error al registrar usuario');
      }

      await _supabase.from('ciudadanos').insert({
        'auth_user_id': user.id,
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'correo': emailNorm,
        'telefono': telefono.trim().isEmpty ? null : telefono.trim(),
        'barrio': barrio.trim().isEmpty ? null : barrio.trim(),
        'foto_url': fotoUrl,
        'foto_path': fotoPath,
        'activo': true,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      final loginRes = await _supabase.auth.signInWithPassword(
        email: emailNorm,
        password: password,
      );

      final loggedUser = loginRes.user;

      if (loggedUser != null) {
        final ciudadano = await _buscarCiudadanoPorUserId(loggedUser.id);
        _currentUser = loggedUser;
        _ciudadanoData = ciudadano;
        notifyListeners();
        return true;
      }

      await _supabase.auth.signOut();
      _currentUser = null;
      _ciudadanoData = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(_traducirError(e));
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final emailNorm = email.trim().toLowerCase();

      final response = await _supabase.auth.signInWithPassword(
        email: emailNorm,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Credenciales incorrectas');
      }

      final ciudadano = await _buscarCiudadanoPorUserId(user.id);

      if (ciudadano == null) {
        await _supabase.auth.signOut();
        throw Exception('Este correo no está registrado como ciudadano');
      }

      _currentUser = user;
      _ciudadanoData = ciudadano;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(_traducirError(e));
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _clearError();

    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'http://localhost:63308/#/reset-password',
      );
      return true;
    } catch (e) {
      _setError('No se pudo enviar el correo');
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _clearError();
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      debugPrint('Error actualizando contraseña: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _ciudadanoData = null;
    _clearError();
    notifyListeners();
  }

  String _traducirError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered')) {
      return 'Este correo ya está registrado';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirma tu correo antes de ingresar';
    }
    if (msg.contains('too many requests')) {
      return 'Demasiados intentos, intenta más tarde';
    }

    return e.message;
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String m) {
    _error = m;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;

    try {
      final ciudadano = await _buscarCiudadanoPorUserId(_currentUser!.id);
      _ciudadanoData = ciudadano;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refrescando datos ciudadano: $e');
    }
  }
}