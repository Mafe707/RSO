import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/admin_auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthService>(
      builder: (context, adminAuthService, _) {
        if (adminAuthService.isCheckingSession) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (adminAuthService.isAdminLoggedIn &&
            adminAuthService.adminData != null) {
          return AdminDashboardScreen(
            adminData: adminAuthService.adminData!,
          );
        }

        return const AdminLoginScreen();
      },
    );
  }
}