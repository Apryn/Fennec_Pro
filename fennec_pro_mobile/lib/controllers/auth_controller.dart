import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  bool _isActivated = false;
  String _currentTraderId = "";
  String? _authError;

  bool get isActivated => _isActivated;
  String get currentTraderId => _currentTraderId;
  String? get authError => _authError;

  // Attempt activation based on mock business rules
  bool activate(String traderId) {
    _authError = null;
    String id = traderId.trim();

    if (id.isEmpty) {
      _authError = "INVALID: Trader ID tidak boleh kosong.";
      notifyListeners();
      return false;
    }

    if (id == "77777") {
      _authError = 
          "WRONG_AFFILIATE: ID terdaftar di tim pusat, tetapi bukan melalui link khusus live ini. Silakan daftar ulang melalui link di bio TikTok kami!";
      notifyListeners();
      return false;
    } else if (RegExp(r'^\d{5,15}$').hasMatch(id)) {
      _isActivated = true;
      _currentTraderId = id;
      _authError = null;
      notifyListeners();
      return true;
    } else {
      _authError = 
          "INVALID: ID tidak ditemukan atau format tidak sesuai. Pastikan Anda sudah mendaftar via link di bio TikTok dan memasukkan 5-15 digit angka.";
      notifyListeners();
      return false;
    }
  }

  // Deactivate and clear credentials
  void deactivate() {
    _isActivated = false;
    _currentTraderId = "";
    _authError = null;
    notifyListeners();
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }
}
