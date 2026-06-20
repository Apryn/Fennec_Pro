import 'package:flutter/material.dart';
import 'theme/cyber_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/trading_controller.dart';
import 'views/auth_screen.dart';
import 'views/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FennecProApp());
}

class FennecProApp extends StatelessWidget {
  const FennecProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create static singletons in controllers to access state easily.
    final authController = AuthController();
    final tradingController = TradingController();

    // Store references in custom inherited provider or global accessors
    FennecState.init(authController, tradingController);

    return ListenableBuilder(
      listenable: authController,
      builder: (context, child) {
        return MaterialApp(
          title: 'FENNEC PRO',
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.themeData,
          home: authController.isActivated
              ? const DashboardScreen()
              : const AuthScreen(),
        );
      },
    );
  }
}

// Simple Service Locator / State Manager to avoid third-party provider complexity
class FennecState {
  static late AuthController auth;
  static late TradingController trading;

  static void init(AuthController a, TradingController t) {
    auth = a;
    trading = t;
  }
}
