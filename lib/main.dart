import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'core/supabase/supabase_config.dart';

import 'services/auth_service.dart';
import 'services/admin_auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/ciudadano_auth_service.dart';

import 'presentation/screens/rol_selection_screen.dart';
import 'presentation/screens/funcionario/funcionario_home_screen.dart';

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
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
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
        title: 'RSO - Ruta Sin Obstáculos',
        theme: AppConfig.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              return const FuncionarioHomeScreen();
            }
            return const RolSelectionScreen();
          },
        ),
      ),
    );
  }
}