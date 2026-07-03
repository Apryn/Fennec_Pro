import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config_service.dart';

class AuthController extends ChangeNotifier {
  bool _isActivated = false;
  String _currentTraderId = "";
  String? _authError;
  bool _isLoading = false;

  bool get isActivated      => _isActivated;
  String get currentTraderId => _currentTraderId;
  String? get authError     => _authError;
  bool get isLoading        => _isLoading;

  AuthController() {
    _loadSession();
  }

  // ─── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('auth_trader_id') ?? '';
      final wasActivated = prefs.getBool('auth_activated') ?? false;

      if (wasActivated && savedId.isNotEmpty) {
        _isActivated = true;
        _currentTraderId = savedId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Fennec] Failed to load auth session: $e');
    }
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_trader_id', _currentTraderId);
      await prefs.setBool('auth_activated', _isActivated);
    } catch (e) {
      debugPrint('[Fennec] Failed to save auth session: $e');
    }
  }

  // ─── Auth Logic ───────────────────────────────────────────────────────────────

  /// Attempt activation based on business rules
  Future<bool> activate(String traderId) async {
    _authError = null;
    final String id = traderId.trim();

    if (id.isEmpty) {
      _authError = "INVALID: Trader ID tidak boleh kosong.";
      notifyListeners();
      return false;
    }

    if (id == "77777") {
      _authError =
          "WRONG_AFFILIATE: ID terdaftar di tim pusat, tetapi bukan melalui link khusus live ini. "
          "Silakan daftar ulang melalui link di bio TikTok kami!";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final isValid = await ConfigService.verifyTraderId(id);
      _isLoading = false;

      if (isValid) {
        _isActivated = true;
        _currentTraderId = id;
        _authError = null;
        await _saveSession(); // persist login
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      debugPrint('[Fennec] Auth error during remote verification: $e');
    }

    _authError =
        "ID tidak ditemukan atau belum terdaftar di bawah link afiliasi kami. "
        "Pastikan Anda mendaftar melalui link di bio TikTok dan hubungi CS / SUPPORT di bawah untuk verifikasi.";
    notifyListeners();
    return false;
  }

  /// Deactivate and clear all persisted credentials
  void deactivate() async {
    _isActivated = false;
    _currentTraderId = "";
    _authError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_trader_id');
      await prefs.remove('auth_activated');
    } catch (e) {
      debugPrint('[Fennec] Failed to clear auth session: $e');
    }
    notifyListeners();
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }
}
