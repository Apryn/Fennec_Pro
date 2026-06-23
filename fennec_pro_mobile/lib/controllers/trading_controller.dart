import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradingController extends ChangeNotifier {
  int _profit = 16659003;
  int _baseTrade = 14000;
  int _martingaleTrade = 17000;
  int _nextTrade = 14000;
  
  bool _isBotRunning = true;
  bool _isMartingaleActive = false;
  int _elapsedSeconds = 0;
  int _consecutiveLosses = 0;
  
  // Risk management parameters
  bool _isAutoDemo = false;
  int _martingaleMultiplierPercent = 122;
  String _maxMartingaleLevels = "always";
  String _resetMartingaleLevel = "off";
  String _stopLossLimit = "4";
  int _takeProfitLimit = 20000000;
  bool _isDemoWallet = false;
  String _platformUrl = 'https://olymptrade.com';
  
  // Full Automation & Anti-Ban Security fields
  bool _isAutoTradingActive = false;
  int _minimumBalanceGuard = 200000;
  int _currentAccountBalance = 10000000;
  String? _lastSignalDirection;
  int _signalId = 0;
  
  Timer? _clockTimer;
  Timer? _stopwatchTimer;
  Timer? _autoSignalTimer;
  
  String _liveTime = "20:00:00";
  
  // Customization/Theme parameters
  String _activeThemeColor = 'neon-green';
  double _glowStrength = 8.0;
  bool _highContrastMode = false;

  final List<Map<String, dynamic>> _historyLogs = [];

  // Getters
  int get profit => _profit;
  int get baseTrade => _baseTrade;
  int get martingaleTrade => _martingaleTrade;
  int get nextTrade => _nextTrade;
  bool get isBotRunning => _isBotRunning;
  bool get isMartingaleActive => _isMartingaleActive;
  int get elapsedSeconds => _elapsedSeconds;
  String get liveTime => _liveTime;
  String get activeThemeColor => _activeThemeColor;
  double get glowStrength => _glowStrength;
  bool get highContrastMode => _highContrastMode;
  List<Map<String, dynamic>> get historyLogs => _historyLogs;

  bool get isAutoDemo => _isAutoDemo;
  int get martingaleMultiplierPercent => _martingaleMultiplierPercent;
  String get maxMartingaleLevels => _maxMartingaleLevels;
  String get resetMartingaleLevel => _resetMartingaleLevel;
  String get stopLossLimit => _stopLossLimit;
  int get takeProfitLimit => _takeProfitLimit;
  bool get isDemoWallet => _isDemoWallet;

  bool get isAutoTradingActive => _isAutoTradingActive;
  int get minimumBalanceGuard => _minimumBalanceGuard;
  int get currentAccountBalance => _currentAccountBalance;
  String? get lastSignalDirection => _lastSignalDirection;
  int get signalId => _signalId;
  String get platformUrl => _platformUrl;

  Color get activeAccentColor {
    switch (_activeThemeColor) {
      case 'neon-green':
        return const Color(0xFF00C853);
      case 'electric-blue':
        return const Color(0xFF00D2FF);
      case 'hot-pink':
        return const Color(0xFFFF007F);
      case 'toxic-purple':
        return const Color(0xFF9D00FF);
      default:
        return const Color(0xFF00C853);
    }
  }

  Color get activeAccentGlow {
    return activeAccentColor.withValues(alpha: 0.35);
  }

  TradingController() {
    _startTimers();
  }

  void _startTimers() {
    // Clock updates
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      _liveTime = DateFormat('HH:mm:ss').format(now);
      notifyListeners();
    });

    // Stopwatch updates
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBotRunning) {
        _elapsedSeconds++;
        notifyListeners();
      }
    });

    // Auto-Signal generator loop (runs every 45 seconds if bot is running and auto-trade is active)
    _autoSignalTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_isBotRunning && _isAutoTradingActive) {
        final direction = (DateTime.now().second % 2 == 0) ? "UP" : "DOWN";
        generateSignal(direction);
      }
    });
  }

  void generateSignal(String direction) {
    if (!_isBotRunning) return;
    _lastSignalDirection = direction;
    _signalId++;
    notifyListeners();
  }

  // Toggle Bot Status
  void toggleBot() {
    _isBotRunning = !_isBotRunning;
    notifyListeners();
  }

  // Update configurations with advanced risk controls
  void updateConfig({
    required int base,
    required int martingale,
    required bool autoDemo,
    required int multiplierPercent,
    required String maxMart,
    required String resetMart,
    required String stopLoss,
    required int takeProfit,
    required bool autoTrading,
    required int minBalance,
    required String platformUrl,
  }) {
    _baseTrade = base;
    _martingaleTrade = martingale;
    _isAutoDemo = autoDemo;
    _martingaleMultiplierPercent = multiplierPercent;
    _maxMartingaleLevels = maxMart;
    _resetMartingaleLevel = resetMart;
    _stopLossLimit = stopLoss;
    _takeProfitLimit = takeProfit;
    _isAutoTradingActive = autoTrading;
    _minimumBalanceGuard = minBalance;
    _platformUrl = platformUrl;
    
    // Recalculate next trade sizing
    _nextTrade = _isMartingaleActive ? _martingaleTrade : _baseTrade;
    notifyListeners();
  }

  void setAutoTradingActive(bool val) {
    _isAutoTradingActive = val;
    notifyListeners();
  }

  void updateAccountBalance(int val) {
    _currentAccountBalance = val;
    
    // Force Stop if Balance Guard triggered
    if (_isAutoTradingActive && _currentAccountBalance < _minimumBalanceGuard) {
      _isAutoTradingActive = false;
      _isBotRunning = false;
      _addHistory("GUARD_STOP", 0, 0);
    }
    notifyListeners();
  }

  // Simulate Winner
  void simulateWin() {
    if (!_isBotRunning) return;
    
    int profitEarned = (_nextTrade * 0.82).round();
    _profit += profitEarned;

    _addHistory("WIN", _nextTrade, profitEarned);

    // Switch back to real wallet on win if auto demo was active
    if (_isDemoWallet) {
      _isDemoWallet = false;
    }

    // Reset Martingale
    _isMartingaleActive = false;
    _consecutiveLosses = 0;
    _nextTrade = _baseTrade;

    // Check Take Profit Limit
    if (_profit >= _takeProfitLimit) {
      _isBotRunning = false;
    }

    notifyListeners();
  }

  // Simulate Loser
  void simulateLoss() {
    if (!_isBotRunning) return;
    
    _profit -= _nextTrade;

    _addHistory("LOSS", _nextTrade, -_nextTrade);

    _isMartingaleActive = true;
    _consecutiveLosses++;
    
    // 1. Check Stop Loss Limit
    if (_stopLossLimit != "off") {
      final limit = int.tryParse(_stopLossLimit);
      if (limit != null && _consecutiveLosses >= limit) {
        if (_isAutoDemo) {
          _isDemoWallet = true;
        } else {
          _isBotRunning = false;
        }
        
        _nextTrade = _baseTrade;
        _consecutiveLosses = 0;
        _isMartingaleActive = false;
        notifyListeners();
        return;
      }
    }

    // 2. Check Martingale Capping / Resets
    bool reachedMaxMart = false;
    if (_maxMartingaleLevels != "always") {
      final limit = int.tryParse(_maxMartingaleLevels);
      if (limit != null && _consecutiveLosses > limit) {
        reachedMaxMart = true;
      }
    }

    bool reachedResetMart = false;
    if (_resetMartingaleLevel != "off") {
      final limit = int.tryParse(_resetMartingaleLevel);
      if (limit != null && _consecutiveLosses > limit) {
        reachedResetMart = true;
      }
    }

    if (reachedMaxMart || reachedResetMart) {
      _nextTrade = _baseTrade;
      _consecutiveLosses = 0;
      _isMartingaleActive = false;
    } else {
      if (_consecutiveLosses == 1) {
        _nextTrade = _martingaleTrade;
      } else {
        // Apply Martingale percentage (e.g. 122% means multiply previous by 2.22)
        double factor = 1.0 + (_martingaleMultiplierPercent / 100.0);
        _nextTrade = (_nextTrade * factor).round();
      }
    }
    
    notifyListeners();
  }

  void _addHistory(String result, int size, int profitDiff) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss').format(now);
    
    final assets = ["BTC/USD (Crypto)", "EUR/USD", "GBP/USD", "AUD/USD", "USD/JPY"];
    final randomAsset = assets[now.second % assets.length];

    _historyLogs.insert(0, {
      'time': timeStr,
      'asset': randomAsset,
      'tradeSize': size,
      'result': result,
      'profitChange': profitDiff,
    });

    if (_historyLogs.length > 30) {
      _historyLogs.removeLast();
    }
  }

  // Theme Personalization Setters
  void setThemeColor(String colorKey) {
    _activeThemeColor = colorKey;
    notifyListeners();
  }

  void setGlowStrength(double val) {
    _glowStrength = val;
    notifyListeners();
  }

  void setHighContrast(bool contrast) {
    _highContrastMode = contrast;
    notifyListeners();
  }

  String formatDuration() {
    final hrs = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$hrs:$mins:$secs";
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _stopwatchTimer?.cancel();
    _autoSignalTimer?.cancel();
    super.dispose();
  }
}
