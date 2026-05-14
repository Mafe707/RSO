import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Barra de estado elegante
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0B1E3D),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

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

        // 👇 Splash animado WOW
        home: const SplashGateway(),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SPLASH SCREEN ANIMADO
/// ═══════════════════════════════════════════════════════════════

class SplashGateway extends StatefulWidget {
  const SplashGateway({super.key});

  @override
  State<SplashGateway> createState() => _SplashGatewayState();
}

class _SplashGatewayState extends State<SplashGateway>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  bool _showText = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1),
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.85,
      end: 1.05,
    ).animate(_glowController);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _showText = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1600));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => const _SessionRouter(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081526),
      body: Stack(
        children: [
          // Fondo degradado elegante
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF081526),
                  Color(0xFF0B1E3D),
                  Color(0xFF13345F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Brillo superior
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.12),
              ),
            ),
          ),

          // Brillo inferior
          Positioned(
            bottom: -140,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.lightBlueAccent.withOpacity(0.08),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _glowAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.03),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.25),
                                  blurRadius: 35,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/rso_logo_final.png',
                              width: 120,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 900),
                  opacity: _showText ? 1 : 0,
                  child: Column(
                    children: [
                      const Text(
                        'Ruta Sin Obstáculos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Analítica • Reportes • Inteligencia Artificial',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: 140,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// ROUTER DE SESIÓN
/// ═══════════════════════════════════════════════════════════════

class _SessionRouter extends StatefulWidget {
  const _SessionRouter();

  @override
  State<_SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<_SessionRouter> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, AdminAuthService,
        CiudadanoAuthService>(
      builder: (context, auth, adminAuth, ciudadanoAuth, _) {
        if (adminAuth.isCheckingSession ||
            ciudadanoAuth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (adminAuth.isAdminLoggedIn &&
            adminAuth.adminData != null) {
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