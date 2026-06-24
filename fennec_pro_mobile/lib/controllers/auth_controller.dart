import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ChangeNotifier {
  bool _isActivated = false;
  String _currentTraderId = "";
  String? _authError;

  bool get isActivated      => _isActivated;
  String get currentTraderId => _currentTraderId;
  String? get authError     => _authError;

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
  bool activate(String traderId) {
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

    if (RegExp(r'^\d{5,15}$').hasMatch(id)) {
      _isActivated = true;
      _currentTraderId = id;
      _authError = null;
      _saveSession(); // persist login
      notifyListeners();
      return true;
    }

    _authError =
        "INVALID: ID tidak ditemukan atau format tidak sesuai. "
        "Pastikan Anda sudah mendaftar via link di bio TikTok dan memasukkan 5-15 digit angka.";
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
