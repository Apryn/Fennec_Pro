import 'package:flutter/material.dart';
import 'theme/cyber_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/trading_controller.dart';
import 'services/background_service.dart';
import 'views/auth_screen.dart';
import 'views/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the background foreground service configuration
  BotForegroundService.init();
  runApp(const FennecProApp());
}

class FennecProApp extends StatefulWidget {
  const FennecProApp({super.key});

  @override
  State<FennecProApp> createState() => _FennecProAppState();
}

class _FennecProAppState extends State<FennecProApp> {
  late final AuthController _authController;
  late final TradingController _tradingController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _tradingController = TradingController();
    // Store references in custom inherited provider or global accessors
    FennecState.init(_authController, _tradingController);
  }

  @override
  void dispose() {
    _authController.dispose();
    _tradingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, child) {
        return MaterialApp(
          title: 'FENNEC PRO',
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.themeData,
          home: _authController.isActivated
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
