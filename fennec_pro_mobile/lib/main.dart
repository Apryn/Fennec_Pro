import 'package:flutter/material.dart';
import 'theme/cyber_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/trading_controller.dart';
import 'services/background_service.dart';
import 'services/config_service.dart';
import 'views/auth_screen.dart';
import 'views/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the background foreground service configuration
  BotForegroundService.init();
  // Fetch remote configurations asynchronously
  ConfigService.fetchConfig().then((_) {
    ConfigService.fetchBridgeScript();
  });
  runApp(const SecmonApp());
}

class SecmonApp extends StatefulWidget {
  const SecmonApp({super.key});

  @override
  State<SecmonApp> createState() => _SecmonAppState();
}

class _SecmonAppState extends State<SecmonApp> {
  late final AuthController _authController;
  late final TradingController _tradingController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _tradingController = TradingController();
    // Store references in custom inherited provider or global accessors
    SecmonState.init(_authController, _tradingController);
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
          title: 'SECMON',
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.themeData,
          home: const DashboardScreen(),
        );
      },
    );
  }
}

// Simple Service Locator / State Manager to avoid third-party provider complexity
class SecmonState {
  static late AuthController auth;
  static late TradingController trading;

  static void init(AuthController a, TradingController t) {
    auth = a;
    trading = t;
  }
}
