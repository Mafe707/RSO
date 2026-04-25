import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'screens/rol_selection_screen.dart';

void main() {
  runApp(const RSOApp());
}

class RSOApp extends StatelessWidget {
  const RSOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'RSO - Ruta Sin Obstáculos',
        theme: AppConfig.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const RolSelectionScreen(),
      ),
    );
  }
}