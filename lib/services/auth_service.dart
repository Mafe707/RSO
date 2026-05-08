import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? _currentUser;
  Map<String, dynamic>? _funcionarioData;

  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get funcionarioData => _funcionarioData;

  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        _currentUser = null;
        _funcionarioData = null;
        notifyListeners();
        return;
      }

      final user = session.user;
      final funcionario = await _buscarFuncionarioPorUserId(user.id);

      if (funcionario == null || funcionario['activo'] != true) {
        _currentUser = null;
        _funcionarioData = null;
        notifyListeners();
        return;
      }

      // Bloquear si está pendiente o rechazado
      final estado = funcionario['estado']?.toString() ?? 'pendiente';
      if (estado != 'aprobado') {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        notifyListeners();
        return;
      }

      _currentUser = user;
      _funcionarioData = funcionario;
      notifyListeners();
    } catch (e) {
      debugPrint('Error revisando sesión: $e');
      _currentUser = null;
      _funcionarioData = null;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _buscarFuncionarioPorUserId(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error buscando funcionario: $e');
      return null;
    }
  }

  // ── REGISTRO ─────────────────────────────────────────────────────────────
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
      final emailNormalizado = email.trim().toLowerCase();

      // 1. Registrar en Supabase Auth con estado pendiente en metadata
      final authResponse = await _supabase.auth.signUp(
        email: emailNormalizado,
        password: password,
        data: {
          'nombre': nombre.trim(),
          'cargo': cargo.trim(),
          'departamento': departamento.trim(),
          'rol': 'funcionario',
          'estado': 'pendiente',
        },
      );

      final user = authResponse.user;
      if (user == null) throw Exception('Error al registrar usuario');

      // 2. Guardar en tabla funcionarios con estado pendiente
      await _supabase.from('funcionarios').insert({
        'auth_user_id': user.id,
        'nombre': nombre.trim(),
        'correo': emailNormalizado,
        'cargo': cargo.trim(),
        'departamento': departamento.trim(),
        'activo': true,
        'rol': 'funcionario',
        'estado': 'pendiente',
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      // NO asignar _currentUser — no debe quedar logueado hasta ser aprobado
      await _supabase.auth.signOut();
      _currentUser = null;
      _funcionarioData = null;

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

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final emailNormalizado = email.trim().toLowerCase();

      final response = await _supabase.auth.signInWithPassword(
        email: emailNormalizado,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Credenciales incorrectas');

      final funcionario = await _buscarFuncionarioPorUserId(user.id);

      if (funcionario == null) {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        throw Exception('Este usuario no está registrado como funcionario');
      }

      if (funcionario['activo'] != true) {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        throw Exception('El funcionario está inactivo');
      }

      // ← NUEVO: verificar estado de aprobación
      final estado = funcionario['estado']?.toString() ?? 'pendiente';

      if (estado == 'pendiente') {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        throw Exception('__pendiente__');
      }

      if (estado == 'rechazado') {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        throw Exception('Tu solicitud fue rechazada. Contacta al administrador.');
      }

      final rol = funcionario['rol']?.toString().toLowerCase();
      if (rol != null && rol != 'funcionario') {
        await _supabase.auth.signOut();
        _currentUser = null;
        _funcionarioData = null;
        throw Exception('Este usuario no tiene permisos de funcionario');
      }

      _currentUser = user;
      _funcionarioData = funcionario;

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

  Future<int> obtenerFuncionariosPendientesCount() async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select('id')
          .eq('estado', 'pendiente');
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _funcionarioData = null;
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
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return 'Este correo ya está registrado';
    }
    if (message.contains('password')) {
      return 'La contraseña no cumple los requisitos';
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
}