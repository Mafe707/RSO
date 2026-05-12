import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

class AdminAuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? _currentAdminUser;
  Map<String, dynamic>? _adminData;

  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _error;

  StreamSubscription<AuthState>? _authSubscription;

  User? get currentAdminUser => _currentAdminUser;
  Map<String, dynamic>? get adminData => _adminData;

  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get error => _error;

  bool get isAdminLoggedIn => _currentAdminUser != null && _adminData != null;

  AdminAuthService() {
    _init();
  }

  void _init() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        await checkAdminSession(notify: true);
        return;
      }

      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        _currentAdminUser = null;
        _adminData = null;
        _error = null;
        _isCheckingSession = false;
        notifyListeners();
      }
    });

    checkAdminSession();
  }

  Future<void> checkAdminSession({bool notify = true}) async {
    try {
      _isCheckingSession = true;
      if (notify) notifyListeners();

      final session = _supabase.auth.currentSession;

      if (session == null) {
        _currentAdminUser = null;
        _adminData = null;
        _isCheckingSession = false;
        if (notify) notifyListeners();
        return;
      }

      final user = session.user;
      final admin = await _buscarAdminPorUserId(user.id);

      if (admin == null) {
        _currentAdminUser = null;
        _adminData = null;
        _isCheckingSession = false;
        if (notify) notifyListeners();
        return;
      }

      final activo = admin['activo'] == true;
      final rol = admin['rol']?.toString().toLowerCase();

      if (!activo || (rol != 'admin' && rol != 'administrador')) {
        _currentAdminUser = null;
        _adminData = null;
        _isCheckingSession = false;
        if (notify) notifyListeners();
        return;
      }

      _currentAdminUser = user;
      _adminData = admin;
      _error = null;
      _isCheckingSession = false;
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error verificando sesión admin: $e');
      _currentAdminUser = null;
      _adminData = null;
      _isCheckingSession = false;
      if (notify) notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _buscarAdminPorUserId(String userId) async {
    try {
      final response = await _supabase
          .from('administradores')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error buscando admin por auth_user_id: $e');
      return null;
    }
  }

  Future<bool> loginAdmin(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final emailNormalizado = email.trim().toLowerCase();

      final response = await _supabase.auth.signInWithPassword(
        email: emailNormalizado,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Credenciales incorrectas');
      }

      final admin = await _buscarAdminPorUserId(user.id);

      if (admin == null) {
        await _supabase.auth.signOut();
        _currentAdminUser = null;
        _adminData = null;
        throw Exception('Este usuario no está registrado como administrador');
      }

      final activo = admin['activo'] == true;
      if (!activo) {
        await _supabase.auth.signOut();
        _currentAdminUser = null;
        _adminData = null;
        throw Exception('El administrador está inactivo');
      }

      final rol = admin['rol']?.toString().toLowerCase();
      if (rol != 'admin' && rol != 'administrador') {
        await _supabase.auth.signOut();
        _currentAdminUser = null;
        _adminData = null;
        throw Exception('Este usuario no tiene permisos de administrador');
      }

      _currentAdminUser = user;
      _adminData = admin;
      _error = null;

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(_traducirErrorAuth(e));
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutAdmin() async {
    await _supabase.auth.signOut();

    _currentAdminUser = null;
    _adminData = null;
    _clearError();

    notifyListeners();
  }

  String _traducirErrorAuth(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('email not confirmed')) {
      return 'El correo electrónico no ha sido confirmado';
    }

    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }

    if (message.contains('too many requests')) {
      return 'Demasiados intentos. Intente más tarde';
    }

    return e.message;
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
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}