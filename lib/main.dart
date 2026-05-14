import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/supabase/supabase_config.dart';

import 'services/auth_service.dart';
import 'services/admin_auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/ciudadano_auth_service.dart';
import 'analytics/services/prediccion_service.dart';

import 'presentation/screens/rol_selection_screen.dart';
import 'presentation/screens/funcionario/funcionario_home_screen.dart';
import 'presentation/screens/administrador/dashboard_screen.dart';
import 'presentation/screens/ciudadano/ciudadano_home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const RSOApp());
}

class RSOApp extends StatelessWidget {
  const RSOApp({super.key});

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
        ChangeNotifierProvider<PrediccionService>(
          create: (_) => PrediccionService(Supabase.instance.client),
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

class _SessionRouter extends StatefulWidget {
  const _SessionRouter();

  @override
  State<_SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<_SessionRouter> {
  @override
  void initState() {
    super.initState();
    // Ya no necesitamos escuchar auth state para recovery
    // El flujo es completamente interno ahora
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, AdminAuthService, CiudadanoAuthService>(
      builder: (context, auth, adminAuth, ciudadanoAuth, _) {
        if (adminAuth.isCheckingSession || ciudadanoAuth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (adminAuth.isAdminLoggedIn && adminAuth.adminData != null) {
          return AdminDashboardScreen(adminData: adminAuth.adminData!);
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