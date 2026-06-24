import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/background_service.dart';

// SharedPreferences keys
class _Prefs {
  static const baseTrade           = 'pref_base_trade';
  static const martingaleTrade     = 'pref_mart_trade';
  static const multiplierPercent   = 'pref_multiplier';
  static const maxMartLevels       = 'pref_max_mart';
  static const resetMartLevel      = 'pref_reset_mart';
  static const stopLoss            = 'pref_stop_loss';
  static const takeProfit          = 'pref_take_profit';
  static const autoDemo            = 'pref_auto_demo';
  static const autoTrading         = 'pref_auto_trading';
  static const minBalance          = 'pref_min_balance';
  static const themeColor          = 'pref_theme_color';
  static const glowStrength        = 'pref_glow_strength';
  static const highContrast        = 'pref_high_contrast';
  static const platformUrl         = 'pref_platform_url';
  static const tradeDuration       = 'pref_trade_duration';
  static const signalMode          = 'pref_signal_mode';
  static const sessionProfit       = 'pref_session_profit';
  static const sessionWins         = 'pref_session_wins';
  static const sessionLosses       = 'pref_session_losses';
  static const historyLogs         = 'pref_history_logs';
  static const isBotRunning        = 'pref_is_bot_running';
  static const isMartActive        = 'pref_is_mart_active';
  static const consecutiveLosses   = 'pref_consecutive_losses';
  static const nextTrade           = 'pref_next_trade';
  static const botStartTime        = 'pref_bot_start_time';
  static const sessionStartBalance = 'pref_session_start_balance';
  static const currencySymbol      = 'pref_currency_symbol';
}

class TradingController extends ChangeNotifier {
  // Trading state — profit resets to 0 each session
  int _profit = 0;
  int _baseTrade = 14000;
  int _martingaleTrade = 17000;
  int _nextTrade = 14000;

  bool _isBotRunning = false;
  bool _isMartingaleActive = false;
  DateTime? _botStartTime;
  int _sessionStartBalance = 0;
  int _consecutiveLosses = 0;
  String _currencySymbol = "Rp";

  // Risk management parameters
  bool _isAutoDemo = false;
  int _martingaleMultiplierPercent = 122;
  String _maxMartingaleLevels = "always";
  String _resetMartingaleLevel = "off";
  String _stopLossLimit = "4";
  int _takeProfitLimit = 20000000;
  bool _isDemoWallet = false;
  String _platformUrl = 'https://olymptrade.com';

  // Full Automation fields
  bool _isAutoTradingActive = false;
  int _minimumBalanceGuard = 200000;
  int _currentAccountBalance = 0;
  String? _lastSignalDirection;
  int _signalId = 0;
  int _lastExecutedSignalId = 0;
  String _activeAsset = "EUR/USD";
  String _signalMode = "follow-winner";

  // Live tick data
  final List<double> _priceTicks = [];

  // ── Trade pending state ───────────────────────────────────────────────
  bool _isTradePending = false;
  int _startBalanceOfTrade = 0;
  int _pendingTradeSize = 0;
  int _pendingTradeSecondsActive = 0;
  int _tradeDurationSeconds = 60;

  // ── Post-resolve cooldown ─────────────────────────────────────────────
  // Setelah setiap trade selesai, tunggu beberapa detik sebelum membuka trade
  // berikutnya. Ini mencegah event RESULT_DETECTED yang terlambat dari WebView
  // mengenai trade baru yang sudah dibuka (bug phantom WIN/LOSS).
  static const int _kPostResolveCooldownSeconds = 6;
  int _postResolveCooldown = 0;

  // Random number generator for coin-flip signal
  final _rng = Random();

  // ── Satu timer saja — menggabungkan clock + stopwatch + auto-signal ────
  // Sebelumnya ada 3 Timer.periodic terpisah, masing-masing memanggil
  // notifyListeners() setiap detik = rebuild widget tree 3x/detik!
  Timer? _masterTimer;
  Timer? _savePrefsTimer;

  // liveTime sebagai ValueNotifier terpisah agar HANYA widget jam yang rebuild
  // setiap detik, bukan seluruh dashboard.
  final ValueNotifier<String> liveTimeNotifier = ValueNotifier("--:--:--");

  // Customization/Theme parameters
  String _activeThemeColor = 'neon-green';
  double _glowStrength = 8.0;
  bool _highContrastMode = false;

  final List<Map<String, dynamic>> _historyLogs = [];

  // Session-level stats (reset setiap bot start)
  int _sessionWins   = 0;
  int _sessionLosses = 0;

  // Indicates settings have been loaded from prefs
  bool _prefsLoaded = false;
  bool get prefsLoaded => _prefsLoaded;

  // Getters
  int get profit                      => _profit;
  int get baseTrade                   => _baseTrade;
  int get martingaleTrade             => _martingaleTrade;
  int get nextTrade                   => _nextTrade;
  bool get isBotRunning               => _isBotRunning;
  bool get isMartingaleActive         => _isMartingaleActive;
  int get elapsedSeconds {
    if (!_isBotRunning || _botStartTime == null) return 0;
    return DateTime.now().difference(_botStartTime!).inSeconds;
  }
  String get liveTime                 => liveTimeNotifier.value;
  String get activeThemeColor         => _activeThemeColor;
  double get glowStrength             => _glowStrength;
  bool get highContrastMode           => _highContrastMode;
  List<Map<String, dynamic>> get historyLogs => _historyLogs;

  bool get isAutoDemo                 => _isAutoDemo;
  int get martingaleMultiplierPercent => _martingaleMultiplierPercent;
  String get maxMartingaleLevels      => _maxMartingaleLevels;
  String get resetMartingaleLevel     => _resetMartingaleLevel;
  String get stopLossLimit            => _stopLossLimit;
  int get takeProfitLimit             => _takeProfitLimit;
  bool get isDemoWallet               => _isDemoWallet;

  bool get isAutoTradingActive        => _isAutoTradingActive;
  int get minimumBalanceGuard         => _minimumBalanceGuard;
  int get currentAccountBalance       => _currentAccountBalance;
  String? get lastSignalDirection     => _lastSignalDirection;
  int get signalId                    => _signalId;
  int get lastExecutedSignalId        => _lastExecutedSignalId;
  String get activeAsset              => _activeAsset;
  String get platformUrl              => _platformUrl;
  String get signalMode               => _signalMode;
  String get currencySymbol           => _currencySymbol;

  void setLastExecutedSignalId(int val) {
    _lastExecutedSignalId = val;
  }

  void updateActiveAsset(String asset) {
    if (asset.isNotEmpty && _activeAsset != asset) {
      _activeAsset = asset;
      _priceTicks.clear();
      notifyListeners();
    }
  }

  void addLivePriceTick(double price) {
    _priceTicks.add(price);
    if (_priceTicks.length > 30) {
      _priceTicks.removeAt(0);
    }
  }
  int get tradeDurationSeconds        => _tradeDurationSeconds;

  // ── Session stats ─────────────────────────────────────────────────────
  int get sessionWins        => _sessionWins;
  int get sessionLosses      => _sessionLosses;
  int get sessionTotalTrades => _sessionWins + _sessionLosses;
  double get sessionWinRate  => sessionTotalTrades == 0 ? 0.0 : (_sessionWins / sessionTotalTrades) * 100;

  // ── Trade countdown & Martingale level for UI ─────────────────────────
  // Berapa detik tersisa dalam trade yang sedang pending
  int get pendingSecondsRemaining {
    if (!_isTradePending) return 0;
    final remaining = _tradeDurationSeconds - _pendingTradeSecondsActive;
    return remaining < 0 ? 0 : remaining;
  }

  // Berapa detik cooldown tersisa sebelum trade berikutnya
  int get postResolveCooldownRemaining => _postResolveCooldown;

  // Level Martingale saat ini (1 = soft mart, 2+ = hard mart)
  int get martingaleLevel => _consecutiveLosses;

  // Apakah trade sedang aktif / pending
  bool get isTradePending => _isTradePending;

  Color get activeAccentColor {
    switch (_activeThemeColor) {
      case 'electric-blue':  return const Color(0xFF00D2FF);
      case 'hot-pink':       return const Color(0xFFFF007F);
      case 'toxic-purple':   return const Color(0xFF9D00FF);
      case 'neon-green':
      default:               return const Color(0xFF00C853);
    }
  }

  Color get activeAccentGlow => activeAccentColor.withOpacity(0.35);

  // ── Smart Signal Generator ───────────────────────────────────────────
  String _generateSmartSignal() {
    if (_signalMode == 'random') {
      return _rng.nextBool() ? 'UP' : 'DOWN';
    }

    if (_signalMode == 'alternate') {
      if (_lastSignalDirection == null) return _rng.nextBool() ? 'UP' : 'DOWN';
      return _lastSignalDirection == 'UP' ? 'DOWN' : 'UP';
    }

    // Mode: follow-winner (Default / Adaptive Trend Following)
    // 1. Deteksi choppy market berdasarkan 2 loss beruntun.
    final recentLogs = _historyLogs
        .where((log) => log['result'] == 'WIN' || log['result'] == 'LOSS')
        .take(4)
        .toList();

    int consecutiveLosses = 0;
    if (recentLogs.length >= 2) {
      for (var log in recentLogs) {
        if (log['result'] == 'LOSS') {
          consecutiveLosses++;
        } else {
          break;
        }
      }
    }

    // 2. Hitung arah momentum pasar jangka pendek dari price ticks
    String momentumDirection = 'UP';
    bool hasMomentum = false;
    if (_priceTicks.length >= 6) {
      final currentPrice = _priceTicks.last;
      final price5sAgo = _priceTicks[_priceTicks.length - 6];
      final diff = currentPrice - price5sAgo;
      if (diff != 0) {
        momentumDirection = diff > 0 ? 'UP' : 'DOWN';
        hasMomentum = true;
      }
    }

    // Jika choppy, balikkan arah momentum (Mean-reversion)
    if (consecutiveLosses >= 2) {
      if (hasMomentum) {
        debugPrint('[Fennec Engine] Choppy market detected. Reversing momentum direction to: ${momentumDirection == 'UP' ? 'DOWN' : 'UP'}');
        return momentumDirection == 'UP' ? 'DOWN' : 'UP';
      } else if (_lastSignalDirection != null) {
        debugPrint('[Fennec Engine] Choppy market detected. Reversing last direction to: ${_lastSignalDirection == 'UP' ? 'DOWN' : 'UP'}');
        return _lastSignalDirection == 'UP' ? 'DOWN' : 'UP';
      }
    }

    // Jika normal, ikuti momentum jika ada tick data
    if (hasMomentum) {
      debugPrint('[Fennec Engine] Following momentum: $momentumDirection');
      return momentumDirection;
    }

    // Fallback jika belum cukup data tick: gunakan follow-winner bawaan
    return _getFollowWinnerDirection();
  }

  String _getFollowWinnerDirection() {
    final lastLog = _historyLogs.firstWhere(
      (log) => log['result'] == 'WIN' || log['result'] == 'LOSS',
      orElse: () => {},
    );

    if (lastLog.isEmpty || _lastSignalDirection == null) {
      return _rng.nextBool() ? 'UP' : 'DOWN';
    }

    final wasWin = lastLog['result'] == 'WIN';
    if (wasWin) {
      return _lastSignalDirection!;
    } else {
      return _lastSignalDirection == 'UP' ? 'DOWN' : 'UP';
    }
  }

  TradingController() {
    _init();
  }

  Future<void> _init() async {
    await _loadPrefs();
    _startTimers();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseTrade                   = prefs.getInt(_Prefs.baseTrade)          ?? 14000;
      _martingaleTrade             = prefs.getInt(_Prefs.martingaleTrade)    ?? 17000;
      _martingaleMultiplierPercent = prefs.getInt(_Prefs.multiplierPercent)  ?? 122;
      _maxMartingaleLevels         = prefs.getString(_Prefs.maxMartLevels)   ?? "always";
      _resetMartingaleLevel        = prefs.getString(_Prefs.resetMartLevel)  ?? "off";
      _stopLossLimit               = prefs.getString(_Prefs.stopLoss)        ?? "4";
      _takeProfitLimit             = prefs.getInt(_Prefs.takeProfit)         ?? 20000000;
      _isAutoDemo                  = prefs.getBool(_Prefs.autoDemo)          ?? false;
      _isAutoTradingActive         = prefs.getBool(_Prefs.autoTrading)       ?? false;
      _minimumBalanceGuard         = prefs.getInt(_Prefs.minBalance)         ?? 200000;
      _activeThemeColor            = prefs.getString(_Prefs.themeColor)      ?? 'neon-green';
      _glowStrength                = prefs.getDouble(_Prefs.glowStrength)    ?? 8.0;
      _highContrastMode            = prefs.getBool(_Prefs.highContrast)      ?? false;
      _platformUrl                 = prefs.getString(_Prefs.platformUrl)     ?? 'https://olymptrade.com';
      _tradeDurationSeconds        = prefs.getInt(_Prefs.tradeDuration)      ?? 60;
      _signalMode                  = prefs.getString(_Prefs.signalMode)      ?? 'follow-winner';
      
      // Load session values
      _profit                      = prefs.getInt(_Prefs.sessionProfit)      ?? 0;
      _sessionWins                 = prefs.getInt(_Prefs.sessionWins)        ?? 0;
      _sessionLosses               = prefs.getInt(_Prefs.sessionLosses)      ?? 0;
      _isBotRunning                = prefs.getBool(_Prefs.isBotRunning)      ?? false;
      _isMartingaleActive          = prefs.getBool(_Prefs.isMartActive)      ?? false;
      _consecutiveLosses           = prefs.getInt(_Prefs.consecutiveLosses)  ?? 0;
      _nextTrade                   = prefs.getInt(_Prefs.nextTrade)          ?? _baseTrade;
      _sessionStartBalance         = prefs.getInt(_Prefs.sessionStartBalance) ?? 0;
      _currencySymbol              = prefs.getString(_Prefs.currencySymbol)   ?? "Rp";

      final startTimeStr = prefs.getString(_Prefs.botStartTime);
      if (startTimeStr != null && startTimeStr.isNotEmpty) {
        _botStartTime = DateTime.tryParse(startTimeStr);
      } else {
        _botStartTime = null;
      }

      final logsStr = prefs.getString(_Prefs.historyLogs);
      if (logsStr != null && logsStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(logsStr);
          _historyLogs.clear();
          _historyLogs.addAll(decoded.map((item) => Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Failed to decode history logs: $e');
        }
      }
    } catch (e) {
      debugPrint('[Fennec] Failed to load prefs: $e');
    }
    _prefsLoaded = true;
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt   (_Prefs.baseTrade,         _baseTrade);
      await prefs.setInt   (_Prefs.martingaleTrade,   _martingaleTrade);
      await prefs.setInt   (_Prefs.multiplierPercent, _martingaleMultiplierPercent);
      await prefs.setString(_Prefs.maxMartLevels,     _maxMartingaleLevels);
      await prefs.setString(_Prefs.resetMartLevel,    _resetMartingaleLevel);
      await prefs.setString(_Prefs.stopLoss,          _stopLossLimit);
      await prefs.setInt   (_Prefs.takeProfit,        _takeProfitLimit);
      await prefs.setBool  (_Prefs.autoDemo,          _isAutoDemo);
      await prefs.setBool  (_Prefs.autoTrading,       _isAutoTradingActive);
      await prefs.setInt   (_Prefs.minBalance,        _minimumBalanceGuard);
      await prefs.setString(_Prefs.themeColor,        _activeThemeColor);
      await prefs.setDouble(_Prefs.glowStrength,      _glowStrength);
      await prefs.setBool  (_Prefs.highContrast,      _highContrastMode);
      await prefs.setString(_Prefs.platformUrl,       _platformUrl);
      await prefs.setInt   (_Prefs.tradeDuration,     _tradeDurationSeconds);
      await prefs.setString(_Prefs.signalMode,        _signalMode);

      // Save session values
      await prefs.setInt   (_Prefs.sessionProfit,     _profit);
      await prefs.setInt   (_Prefs.sessionWins,       _sessionWins);
      await prefs.setInt   (_Prefs.sessionLosses,     _sessionLosses);
      await prefs.setBool  (_Prefs.isBotRunning,      _isBotRunning);
      await prefs.setBool  (_Prefs.isMartActive,      _isMartingaleActive);
      await prefs.setInt   (_Prefs.consecutiveLosses, _consecutiveLosses);
      await prefs.setInt   (_Prefs.nextTrade,         _nextTrade);
      await prefs.setInt   (_Prefs.sessionStartBalance,_sessionStartBalance);
      await prefs.setString(_Prefs.botStartTime,       _botStartTime?.toIso8601String() ?? "");
      await prefs.setString(_Prefs.currencySymbol,     _currencySymbol);
      await prefs.setString(_Prefs.historyLogs,       jsonEncode(_historyLogs));
    } catch (e) {
      debugPrint('[Fennec] Failed to save prefs: $e');
    }
  }

  void _savePrefsDebounced() {
    _savePrefsTimer?.cancel();
    _savePrefsTimer = Timer(const Duration(milliseconds: 500), () {
      _savePrefs();
    });
  }

  String _formatRp(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final sign = amount < 0 ? '-' : '';
    final space = _currencySymbol.length > 1 ? ' ' : '';
    return "$sign$_currencySymbol$space${formatter.format(amount.abs())}";
  }

  void _updateForegroundNotification() {
    if (!_isBotRunning) return;
    String status;
    if (_isTradePending) {
      final direction = _lastSignalDirection ?? "UP";
      final martLevel = _consecutiveLosses > 0 ? " | Mart Lv.$_consecutiveLosses" : "";
      status = "Trade #$_signalId aktif ($direction)$martLevel | P/L: ${_formatRp(_profit)}";
    } else {
      status = "Bot standby | Sesi P/L: ${_formatRp(_profit)}";
    }
    BotForegroundService.updateNotification(status: status);
  }

  // ─── Timer Tunggal ──────────────────────────────────────────────────────────
  //
  // SEMUA tugas timer digabung dalam satu Timer.periodic(1 detik):
  //   • Update jam (liveTimeNotifier — TIDAK memicu rebuild widget tree)
  //   • Update stopwatch elapsed (notifyListeners hanya jika bot running)
  //   • Auto-signal state machine
  //
  // Sebelumnya ada 3 timer terpisah → setiap detik 3x notifyListeners → lag!

  void _startTimers() {
    _masterTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 1. Clock — update via ValueNotifier, tidak trigger rebuild full widget tree
      liveTimeNotifier.value = DateFormat('HH:mm:ss').format(DateTime.now());

      // 2. Stopwatch — hanya rebuild jika bot sedang berjalan
      if (_isBotRunning) {
        // dynamic calculation via elapsedSeconds getter
      }

      // 3. Auto-signal state machine
      // ─────────────────────────────────────────────────────────────────────
      //  [PENDING]  → tunggu durasi + buffer → fallback LOSS jika tidak ada response
      //  [COOLDOWN] → tunggu event WebView lama settle sebelum buka trade baru
      //  [IDLE]     → analisis trend → buka trade baru
      if (_isBotRunning && _isAutoTradingActive) {
        if (_isTradePending) {
          _pendingTradeSecondsActive++;
          final maxWait = _tradeDurationSeconds + 8; // 8 seconds buffer is safe for slower balance updates or delays
          if (_pendingTradeSecondsActive >= maxWait) {
            // Deteksi hasil secara deterministik lewat saldo jika WebView tidak mengirimkan event
            final isWin = _currentAccountBalance > _startBalanceOfTrade;
            debugPrint('[Fennec] ⏱️ Durasi trade tercapai. Menyelesaikan via perbandingan saldo: ${isWin ? "WIN" : "LOSS"}');
            _resolvePendingTrade(isWin: isWin);
            return;
          }
        } else if (_postResolveCooldown > 0) {
          _postResolveCooldown--;
        } else {
          if (_shouldTriggerSignal(DateTime.now(), _tradeDurationSeconds)) {
            generateSignal(_generateSmartSignal());
          }
          return;
        }
      }

      // Satu notifyListeners per detik untuk update stopwatch + status
      if (_isBotRunning) notifyListeners();
    });
  }

  bool _shouldTriggerSignal(DateTime time, int durationSeconds) {
    // Kita menembak sinyal 2 detik sebelum batas candle (candle boundary)
    // untuk mengompensasi delay acak simulasi klik di WebView (rata-rata 2.5 detik).
    final targetTime = time.add(const Duration(seconds: 2));
    
    if (durationSeconds == 15) {
      return targetTime.second % 15 == 0;
    } else if (durationSeconds == 30) {
      return targetTime.second % 30 == 0;
    } else if (durationSeconds == 60) {
      return targetTime.second == 0;
    } else if (durationSeconds == 120) {
      return targetTime.minute % 2 == 0 && targetTime.second == 0;
    } else if (durationSeconds == 300) {
      return targetTime.minute % 5 == 0 && targetTime.second == 0;
    }
    return targetTime.second == 0;
  }

  // ─── Signal & Trade Open ──────────────────────────────────────────────────

  void generateSignal(String direction) {
    if (!_isBotRunning) return;

    // Jika masih ada trade pending, JANGAN buka yang baru.
    // Ini mencegah "force-loss" palsu yang terjadi sebelumnya.
    if (_isTradePending) {
      debugPrint('[Fennec] generateSignal called while trade is pending — skipped');
      return;
    }

    _lastSignalDirection = direction;
    _signalId++;

    _startBalanceOfTrade = _currentAccountBalance;
    _pendingTradeSize    = _nextTrade;
    _isTradePending      = true;
    _pendingTradeSecondsActive = 0;

    _addHistory("OPEN", _nextTrade, 0);
    _updateForegroundNotification();
    notifyListeners();
  }

  // ─── Bot Control ─────────────────────────────────────────────────────────────

  void toggleBot() {
    _isBotRunning = !_isBotRunning;
    if (_isBotRunning) {
      _profit                = 0;
      _consecutiveLosses     = 0;
      _isMartingaleActive    = false;
      _nextTrade             = _baseTrade;
      _historyLogs.clear();
      _isTradePending        = false;
      _pendingTradeSecondsActive = 0;
      _postResolveCooldown   = 0;
      _startBalanceOfTrade   = _currentAccountBalance;
      _sessionStartBalance   = _currentAccountBalance;
      _botStartTime          = DateTime.now();
      _sessionWins           = 0;  // reset session stats
      _sessionLosses         = 0;
      _signalId              = 0;
      _lastExecutedSignalId  = 0;
      _lastSignalDirection   = null;
      BotForegroundService.startService();
      _updateForegroundNotification();
      _savePrefsDebounced();
    } else {
      if (_isTradePending) {
        _resolvePendingTrade(isWin: false);
      }
      BotForegroundService.stopService();
    }
    notifyListeners();
  }

  // ─── Configuration ────────────────────────────────────────────────────────────

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
    required String signalMode,
  }) {
    _baseTrade                   = base;
    _martingaleTrade             = martingale;
    _isAutoDemo                  = autoDemo;
    _martingaleMultiplierPercent = multiplierPercent;
    _maxMartingaleLevels         = maxMart;
    _resetMartingaleLevel        = resetMart;
    _stopLossLimit               = stopLoss;
    _takeProfitLimit             = takeProfit;
    _isAutoTradingActive         = autoTrading;
    _minimumBalanceGuard         = minBalance;
    _platformUrl                 = platformUrl;
    _tradeDurationSeconds        = tradeDuration;
    _signalMode                  = signalMode;
    _nextTrade = _isMartingaleActive ? _martingaleTrade : _baseTrade;
    _savePrefsDebounced();
    notifyListeners();
  }

  void setAutoTradingActive(bool val) {
    _isAutoTradingActive = val;
    _savePrefsDebounced();
    notifyListeners();
  }

  // ─── Balance Update (dipanggil WebView setiap ada perubahan saldo) ────────────
  //
  // Hanya digunakan untuk:
  //  1. Deteksi WIN: balance naik dari _startBalanceOfTrade
  //  2. Balance guard protection
  //
  void updateAccountBalance(int val, {bool isDemo = false, String currency = "Rp"}) {
    final bool walletTypeChanged = _isDemoWallet != isDemo;
    _currentAccountBalance = val;
    _isDemoWallet = isDemo;
    _currencySymbol = currency;

    if (walletTypeChanged) {
      _isTradePending = false;
    }

    if (_isBotRunning) {
      if (walletTypeChanged || _sessionStartBalance == 0) {
        _sessionStartBalance = val;
      }
      if (_sessionStartBalance > 0) {
        _profit = val - _sessionStartBalance;
      }
      _savePrefsDebounced();
    }

    // Deteksi WIN dari perubahan balance — HANYA jika trade benar-benar pending
    if (_isBotRunning && _isTradePending && _startBalanceOfTrade > 0) {
      if (val > _startBalanceOfTrade) {
        debugPrint('[Fennec] 🟢 WIN detected via balance: $val > $_startBalanceOfTrade');
        _resolvePendingTrade(isWin: true, newBalance: val);
        // Setelah resolve, return langsung — jangan lanjut cek guard
        notifyListeners();
        return;
      }
    }

    // Balance guard
    if (_isAutoTradingActive && !_isDemoWallet &&
        _currentAccountBalance < _minimumBalanceGuard) {
      _isAutoTradingActive = false;
      _isBotRunning = false;
      BotForegroundService.stopService();
      _addHistory("GUARD_STOP", 0, 0);
    }
    notifyListeners();
  }

  // ─── Resolve dari WebView RESULT_DETECTED (mode auto maupun manual) ───────────
  //
  // Dipanggil dari web_tab.dart ketika WebView mendeteksi teks WIN/LOSS.
  // Hanya aktif jika masih ada trade pending (mencegah stale event dari trade lama
  // yang terlambat mengenai trade baru).
  //
  void resolveCurrentTradeFromWebView({required bool isWin}) {
    if (!_isBotRunning) return;
    if (!_isTradePending) {
      // Tidak ada trade pending — abaikan event WebView yang terlambat
      debugPrint('[Fennec] ⚠️ resolveFromWebView called but no trade pending — ignored');
      return;
    }
    debugPrint('[Fennec] ${isWin ? "🟢 WIN" : "🔴 LOSS"} resolved via WebView RESULT_DETECTED');
    _resolvePendingTrade(isWin: isWin);
  }

  // ─── Trade Resolution — Inti Logika Martingale ────────────────────────────────
  //
  // WIN  → catat profit, reset ke base trade, aktifkan cooldown
  // LOSS → hitung Martingale kompensasi (modal × multiplier) agar saat WIN
  //        berikutnya semua loss sebelumnya tertutup + sedikit profit
  //
  void _resolvePendingTrade({required bool isWin, int? newBalance}) {
    // Guard utama: pastikan memang ada trade pending
    if (!_isTradePending) return;

    final pendingIndex = _historyLogs.indexWhere((log) => log['result'] == 'OPEN');

    int profitDiff = 0;

    if (isWin) {
      HapticFeedback.heavyImpact();
      // Hitung profit dari perubahan balance (akurat) atau estimasi 82% payout
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

      if (_isDemoWallet) _isDemoWallet = false;

      _sessionWins++;  // catat WIN ke stats sesi

      // Reset Martingale → kembali ke base trade
      _isMartingaleActive = false;
      _consecutiveLosses  = 0;
      _nextTrade          = _baseTrade;

      if (_profit >= _takeProfitLimit) {
        _isBotRunning = false;
        BotForegroundService.stopService();
      }
    } else {
      HapticFeedback.lightImpact();
      // LOSS
      profitDiff = -_pendingTradeSize;
      _profit += profitDiff;

      _sessionLosses++;  // catat LOSS ke stats sesi

      if (pendingIndex != -1) {
        _historyLogs[pendingIndex]['result'] = 'LOSS';
        _historyLogs[pendingIndex]['profitChange'] = profitDiff;
      }

      _isMartingaleActive = true;
      _consecutiveLosses++;

      // 1. Cek Stop Loss
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
        // 2. Cek batas max Martingale / reset Martingale
        bool reachedMaxMart = false;
        if (_maxMartingaleLevels != "always") {
          final limit = int.tryParse(_maxMartingaleLevels);
          if (limit != null && _consecutiveLosses > limit) reachedMaxMart = true;
        }

        bool reachedResetMart = false;
        if (_resetMartingaleLevel != "off") {
          final limit = int.tryParse(_resetMartingaleLevel);
          if (limit != null && _consecutiveLosses > limit) reachedResetMart = true;
        }

        if (reachedMaxMart || reachedResetMart) {
          _nextTrade = _baseTrade;
          _consecutiveLosses = 0;
          _isMartingaleActive = false;
        } else {
          // ── MARTINGALE KOMPENSASI ──────────────────────────────────────
          // Loss ke-1 → Soft Martingale (dari config)
          // Loss ke-2+ → stake sebelumnya × (1 + multiplierPercent/100)
          // Sehingga saat WIN, semua loss sebelumnya tertutup + profit kecil
          if (_consecutiveLosses == 1) {
            _nextTrade = _martingaleTrade;
          } else {
            final factor = 1.0 + (_martingaleMultiplierPercent / 100.0);
            _nextTrade = (_nextTrade * factor).round();
          }
        }
      }
    }

    // Tandai trade selesai
    _isTradePending = false;

    // ── Aktifkan cooldown ─────────────────────────────────────────────────
    // Memberi waktu event WebView lama (RESULT_DETECTED yang terlambat) untuk
    // settle sebelum trade berikutnya dibuka. Ini mencegah phantom WIN/LOSS.
    _postResolveCooldown = _kPostResolveCooldownSeconds;

    _updateForegroundNotification();
    _savePrefsDebounced();
    notifyListeners();
  }

  // ─── Simulate (Developer / Debug Mode) ───────────────────────────────────────
  //
  // Tombol debug di dashboard. Tidak bergantung pada auto-trading state.

  void simulateWin() {
    if (!_isBotRunning) return;
    if (!_isTradePending) {
      // Buka trade sementara lalu langsung resolve
      _pendingTradeSize = _nextTrade;
      _isTradePending   = true;
      _addHistory("OPEN", _nextTrade, 0);
    }
    _resolvePendingTrade(isWin: true);
  }

  void simulateLoss() {
    if (!_isBotRunning) return;
    if (!_isTradePending) {
      _pendingTradeSize = _nextTrade;
      _isTradePending   = true;
      _addHistory("OPEN", _nextTrade, 0);
    }
    _resolvePendingTrade(isWin: false);
  }

  void _addHistory(String result, int size, int profitDiff) {
    final timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
    _historyLogs.insert(0, {
      'time':         timeStr,
      'asset':        _activeAsset,
      'tradeSize':    size,
      'result':       result,
      'profitChange': profitDiff,
    });
    if (_historyLogs.length > 50) _historyLogs.removeLast();
  }

  // ─── Theme Setters ────────────────────────────────────────────────────────────

  void setThemeColor(String colorKey) {
    _activeThemeColor = colorKey;
    _savePrefsDebounced();
    notifyListeners();
  }

  void setGlowStrength(double val) {
    _glowStrength = val;
    _savePrefsDebounced();
    notifyListeners();
  }

  void setHighContrast(bool contrast) {
    _highContrastMode = contrast;
    _savePrefsDebounced();
    notifyListeners();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String formatDuration() {
    final seconds = elapsedSeconds;
    final hrs  = (seconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hrs:$mins:$secs";
  }

  @override
  void dispose() {
    _masterTimer?.cancel();
    if (_savePrefsTimer?.isActive == true) {
      _savePrefsTimer?.cancel();
      _savePrefs();
    }
    liveTimeNotifier.dispose();
    super.dispose();
  }
}
