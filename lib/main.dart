import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/supabase/supabase_config.dart';

import 'services/auth_service.dart';
import 'services/admin_auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/ciudadano_auth_service.dart';

import 'presentation/screens/rol_selection_screen.dart';
import 'presentation/screens/funcionario/funcionario_home_screen.dart';
import 'presentation/screens/administrador/dashboard_screen.dart';
import 'presentation/screens/ciudadano/ciudadano_home_screen.dart';
import 'presentation/screens/ciudadano/reset_password_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const RSOApp());
}

class RSOApp extends StatefulWidget {
  const RSOApp({super.key});

  @override
  State<RSOApp> createState() => _RSOAppState();
}

class _RSOAppState extends State<RSOApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<AdminAuthService>(
          create: (_) => AdminAuthService(),
        ),
        ChangeNotifierProvider<DenunciaService>(
          create: (_) => DenunciaService(),
        ),
        ChangeNotifierProvider<CiudadanoAuthService>(
          create: (_) => CiudadanoAuthService(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'RSO - Ruta Sin Obstáculos',
        theme: AppConfig.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const _SessionRouter(),
      ),
    );
  }
}

class _SessionRouter extends StatelessWidget {
  const _SessionRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, AdminAuthService, CiudadanoAuthService>(
      builder: (context, auth, adminAuth, ciudadanoAuth, _) {
        final adminChecking = adminAuth.isCheckingSession;

        if (adminChecking || ciudadanoAuth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (adminAuth.isAdminLoggedIn && adminAuth.adminData != null) {
          return AdminDashboardScreen(
            adminData: adminAuth.adminData!,
          );
        }

        if (auth.isLoggedIn) {
          return const FuncionarioHomeScreen();
        }

        if (ciudadanoAuth.isLoggedIn) {
          return const CiudadanoHomeScreen();
        }

        return const RolSelectionScreen();
      },
    );
  }
}