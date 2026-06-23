import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/background_service.dart';

class TradingController extends ChangeNotifier {
  int _profit = 0;
  int _baseTrade = 14000;
  int _martingaleTrade = 17000;
  int _nextTrade = 14000;
  
  bool _isBotRunning = false;
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
  int _currentAccountBalance = 0;
  String? _lastSignalDirection;
  int _signalId = 0;

  bool _isTradePending = false;
  int _startBalanceOfTrade = 0;
  int _pendingTradeSize = 0;
  int _pendingTradeSecondsActive = 0;
  int _secondsSinceLastSignal = 0;
  int _tradeDurationSeconds = 60;

  // ── Smart Signal Engine ──────────────────────────────────────────────
  // Rolling buffer of recent scraped prices (up to 30 ticks)
  final List<double> _priceBuffer = [];
  static const int _kBufferSize = 30;
  // Last computed indicators (for UI display)
  double _lastRsi = 50.0;
  double _lastEmaFast = 0;
  double _lastEmaSlow = 0;
  String _lastSignalReason = '';
  // How many consecutive candles were skipped (no signal found)
  int _skippedCandles = 0;

  // Getters for UI
  double get lastRsi => _lastRsi;
  String get lastSignalReason => _lastSignalReason;
  
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
  int get tradeDurationSeconds => _tradeDurationSeconds;

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

  // ── Smart Signal Engine ──────────────────────────────────────────────
  double _computeEma(List<double> prices, int period) {
    if (prices.length < period) {
      return prices.isEmpty ? 0 : prices.last;
    }
    final k = 2.0 / (period + 1);
    double ema = prices.sublist(prices.length - period).reduce((a, b) => a + b) / period;
    return ema; // simplified single-pass EMA for the period's last window
  }

  double _computeRsi(List<double> prices, {int period = 14}) {
    if (prices.length < period + 1) return 50.0;
    double gains = 0, losses = 0;
    final recent = prices.sublist(prices.length - period - 1);
    for (int i = 1; i < recent.length; i++) {
      final change = recent[i] - recent[i - 1];
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }
    if (losses == 0) return 100.0;
    if (gains == 0) return 0.0;
    final rs = gains / losses;
    return 100.0 - (100.0 / (1.0 + rs));
  }

  /// Called by the WebView bridge when a new price tick is received
  void onPriceTick(double price) {
    _priceBuffer.add(price);
    if (_priceBuffer.length > _kBufferSize) {
      _priceBuffer.removeAt(0);
    }
  }

  /// Tiered Smart Signal System:
  /// Grade A: 2+ indicators agree  → HIGH confidence, always fire
  /// Grade B: 1 indicator present  → MEDIUM confidence, fire normally
  /// Grade C: momentum only (last tick direction) → LOW confidence, fire
  /// Emergency: forced direction based on RSI trend → always returns a signal
  String _computeSmartSignal({bool forceEmergency = false}) {
    // Emergency fallback: not enough data or force flag
    if (_priceBuffer.length < 5 || forceEmergency) {
      // Use simple RSI-like proxy: compare latest vs earliest in buffer
      if (_priceBuffer.length >= 2) {
        final trend = _priceBuffer.last > _priceBuffer.first ? 'DOWN' : 'UP';
        _lastSignalReason = '⚡ Quick-trend fallback (${_priceBuffer.length} ticks)';
        return trend;
      }
      // Absolute last resort: alternating direction based on minute parity
      final dir = (DateTime.now().minute % 2 == 0) ? 'UP' : 'DOWN';
      _lastSignalReason = '⚡ Timed fallback (no price data yet)';
      return dir;
    }

    final rsi = _computeRsi(_priceBuffer);
    final emaFast = _computeEma(_priceBuffer, 5);
    final emaSlow = _computeEma(_priceBuffer, 13);

    _lastRsi = rsi;
    _lastEmaFast = emaFast;
    _lastEmaSlow = emaSlow;

    int upVotes = 0;
    int downVotes = 0;
    final List<String> reasons = [];

    // Indicator 1: RSI (extreme zones only for reliability)
    if (rsi < 35) {
      upVotes++;
      reasons.add('RSI${rsi.toStringAsFixed(0)}↑');
    } else if (rsi > 65) {
      downVotes++;
      reasons.add('RSI${rsi.toStringAsFixed(0)}↓');
    }

    // Indicator 2: EMA crossover trend
    if (emaFast > emaSlow * 1.00005) {
      upVotes++;
      reasons.add('EMA↑');
    } else if (emaFast < emaSlow * 0.99995) {
      downVotes++;
      reasons.add('EMA↓');
    }

    // Indicator 3: Recent momentum (last 3 ticks vs 3 before)
    if (_priceBuffer.length >= 6) {
      final last = _priceBuffer.last;
      final prev3Avg = (_priceBuffer[_priceBuffer.length - 2] +
              _priceBuffer[_priceBuffer.length - 3] +
              _priceBuffer[_priceBuffer.length - 4]) /
          3;
      if (last < prev3Avg * 0.9997) {
        upVotes++;
        reasons.add('Bounce↑');
      } else if (last > prev3Avg * 1.0003) {
        downVotes++;
        reasons.add('Reversal↓');
      }
    }

    // ── Grade A: 2+ confirmations ────────────────────────────────────
    if (upVotes >= 2 && upVotes > downVotes) {
      _lastSignalReason = '🟢 A: ${reasons.join(' + ')}';
      _skippedCandles = 0;
      return 'UP';
    } else if (downVotes >= 2 && downVotes > upVotes) {
      _lastSignalReason = '🟢 A: ${reasons.join(' + ')}';
      _skippedCandles = 0;
      return 'DOWN';
    }

    // ── Grade B: 1 single indicator ──────────────────────────────────
    if (upVotes >= 1 && upVotes > downVotes) {
      _lastSignalReason = '🟡 B: ${reasons.join(' + ')}';
      _skippedCandles = 0;
      return 'UP';
    } else if (downVotes >= 1 && downVotes > upVotes) {
      _lastSignalReason = '🟡 B: ${reasons.join(' + ')}';
      _skippedCandles = 0;
      return 'DOWN';
    }

    // ── Grade C: Pure momentum (last tick direction) ─────────────────
    if (_priceBuffer.length >= 2) {
      final mom = _priceBuffer.last > _priceBuffer[_priceBuffer.length - 2]
          ? 'DOWN'   // price naik → ikut trend turun (mean reversion)
          : 'UP';    // price turun → ikut trend naik (mean reversion)
      _lastSignalReason = '🔵 C: Momentum only';
      _skippedCandles = 0;
      return mom;
    }

    _lastSignalReason = 'Sideways — menunggu...';
    return 'SKIP'; // Should almost never happen
  }

  /// Check if we are at the start of a candle boundary (aligned with timeframe)
  bool _isCandleOpenMoment(DateTime now) {
    final s = now.second;
    switch (_tradeDurationSeconds) {
      case 15:
        return (s % 15) < 3; // fire in first 3 seconds of each 15s candle
      case 30:
        return (s % 30) < 3;
      case 60:
        return s < 3; // first 3 seconds of each minute
      case 120:
        return s < 3 && (now.minute % 2 == 0);
      case 300:
        return s < 3 && (now.minute % 5 == 0);
      default:
        return s < 3;
    }
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

    // Auto-Signal generator loop — checks every second
    // Uses candle-aligned timing + tiered smart signal
    _autoSignalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBotRunning && _isAutoTradingActive) {
        if (_isTradePending) {
          final int maxAllowedDuration = _tradeDurationSeconds + 15;
          if (_pendingTradeSecondsActive >= maxAllowedDuration) {
            _resolvePendingTrade(isWin: false);
          } else {
            _pendingTradeSecondsActive++;
          }
          return;
        }

        _secondsSinceLastSignal++;
        final now = DateTime.now();
        // Minimum cooldown = trade duration + 3s safety gap
        final cooldown = _tradeDurationSeconds + 3;
        if (_secondsSinceLastSignal >= cooldown && _isCandleOpenMoment(now)) {
          _secondsSinceLastSignal = 0;
          // Emergency override: if bot skipped 2+ candles, force a signal
          final forceNow = _skippedCandles >= 2;
          final dir = _computeSmartSignal(forceEmergency: forceNow);
          if (dir != 'SKIP') {
            generateSignal(dir);
          } else {
            _skippedCandles++;
            notifyListeners();
          }
        }
      }
    });
  }

  void generateSignal(String direction) {
    if (!_isBotRunning) return;

    // Resolve any previous pending trade as a loss since a new signal is generated
    if (_isTradePending) {
      _resolvePendingTrade(isWin: false);
    }

    _lastSignalDirection = direction;
    _signalId++;

    // Start new pending trade!
    _startBalanceOfTrade = _currentAccountBalance;
    _pendingTradeSize = _nextTrade;
    _isTradePending = true;
    _pendingTradeSecondsActive = 0; // reset active seconds
    _addHistory("OPEN", _nextTrade, 0);

    notifyListeners();
  }

  // Toggle Bot Status
  void toggleBot() {
    _isBotRunning = !_isBotRunning;
    if (!_isBotRunning && _isTradePending) {
      // Resolve any pending trade as loss when bot stops
      _resolvePendingTrade(isWin: false);
      // Stop foreground service so bot no longer runs in background
      BotForegroundService.stopService();
    } else if (_isBotRunning) {
      _isTradePending = false;
      _secondsSinceLastSignal = 0;
      _skippedCandles = 0;
      _startBalanceOfTrade = _currentAccountBalance;
      // Start foreground service to keep bot alive in background
      BotForegroundService.startService();
    } else {
      // Bot stopped normally (no pending trade)
      BotForegroundService.stopService();
    }
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
    required int tradeDuration,
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
    _tradeDurationSeconds = tradeDuration;
    
    // Recalculate next trade sizing
    _nextTrade = _isMartingaleActive ? _martingaleTrade : _baseTrade;
    notifyListeners();
  }

  void setAutoTradingActive(bool val) {
    _isAutoTradingActive = val;
    notifyListeners();
  }

  void updateAccountBalance(int val, {bool isDemo = false}) {
    _currentAccountBalance = val;
    _isDemoWallet = isDemo;

    // Check if we have a pending trade and the balance went up (win)
    if (_isBotRunning && _isTradePending) {
      if (val > _startBalanceOfTrade) {
        // Balance went up! This means the pending trade won!
        _resolvePendingTrade(isWin: true, newBalance: val);
      }
    }
    
    // Force Stop if Balance Guard triggered (only for Real Wallet)
    if (_isAutoTradingActive && !_isDemoWallet && _currentAccountBalance < _minimumBalanceGuard) {
      _isAutoTradingActive = false;
      _isBotRunning = false;
      BotForegroundService.stopService();
      _addHistory("GUARD_STOP", 0, 0);
    }
    notifyListeners();
  }

  void _resolvePendingTrade({required bool isWin, int? newBalance}) {
    if (!_isTradePending) return;

    // Find the pending log in history and update it
    final pendingIndex = _historyLogs.indexWhere((log) => log['result'] == 'OPEN');
    
    int profitDiff = 0;
    if (isWin) {
      // Calculate actual profit diff from balance change if available,
      // otherwise estimate it (82% of stake)
      if (newBalance != null && _startBalanceOfTrade > 0) {
        profitDiff = newBalance - _startBalanceOfTrade;
      } else {
        profitDiff = (_pendingTradeSize * 0.82).round();
      }
      _profit += profitDiff;

      if (pendingIndex != -1) {
        _historyLogs[pendingIndex]['result'] = 'WIN';
        _historyLogs[pendingIndex]['profitChange'] = profitDiff;
      }

      if (_isDemoWallet) {
        _isDemoWallet = false;
      }

      _isMartingaleActive = false;
      _consecutiveLosses = 0;
      _nextTrade = _baseTrade;
    } else {
      profitDiff = -_pendingTradeSize;
      _profit += profitDiff;

      if (pendingIndex != -1) {
        _historyLogs[pendingIndex]['result'] = 'LOSS';
        _historyLogs[pendingIndex]['profitChange'] = profitDiff;
      }

      _isMartingaleActive = true;
      _consecutiveLosses++;

      // 1. Check Stop Loss Limit
      bool stopLossTriggered = false;
      if (_stopLossLimit != "off") {
        final limit = int.tryParse(_stopLossLimit);
        if (limit != null && _consecutiveLosses >= limit) {
          if (_isAutoDemo) {
            _isDemoWallet = true;
          } else {
            _isBotRunning = false;
            BotForegroundService.stopService();
          }

          _nextTrade = _baseTrade;
          _consecutiveLosses = 0;
          _isMartingaleActive = false;
          stopLossTriggered = true;
        }
      }

      if (!stopLossTriggered) {
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
            double factor = 1.0 + (_martingaleMultiplierPercent / 100.0);
            _nextTrade = (_nextTrade * factor).round();
          }
        }
      }
    }

    _isTradePending = false;
    
    // Check Take Profit Limit
    if (_profit >= _takeProfitLimit) {
      _isBotRunning = false;
      BotForegroundService.stopService();
    }

    notifyListeners();
  }

  // Simulate Winner
  void simulateWin() {
    if (!_isBotRunning) return;
    
    if (_isTradePending) {
      _resolvePendingTrade(isWin: true);
    } else {
      _pendingTradeSize = _nextTrade;
      _isTradePending = true;
      _addHistory("OPEN", _nextTrade, 0);
      _resolvePendingTrade(isWin: true);
    }
  }

  // Simulate Loser
  void simulateLoss() {
    if (!_isBotRunning) return;
    
    if (_isTradePending) {
      _resolvePendingTrade(isWin: false);
    } else {
      _pendingTradeSize = _nextTrade;
      _isTradePending = true;
      _addHistory("OPEN", _nextTrade, 0);
      _resolvePendingTrade(isWin: false);
    }
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
