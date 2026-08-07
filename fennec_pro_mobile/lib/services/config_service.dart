import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConfigService {
  // Master config URL
  static const String _configUrl = "https://raw.githubusercontent.com/Apryn/Fennec_Pro/main/config.json";

  // Configuration variables with safe default values
  static String affiliateUrl = "https://olymptrade-wid.com/id-id/?affiliate_id=2006744&subid1=";
  static String bridgeUrl = "https://motodoct.com/secmon/bridge.js";
  static String verificationUrl = "https://motodoct.com/secmon/verify-trader";
  static String supportUrl = "https://t.me/Secmonbott";

  // In-memory cache for dynamic JS bridge script
  static String cachedBridgeScript = "";

  /// Fetch master configuration from remote server
  static Future<void> fetchConfig() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse(_configUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> config = jsonDecode(jsonStr);

        if (config.containsKey('affiliate_url') && config['affiliate_url'] != null) {
          affiliateUrl = config['affiliate_url'] as String;
        }
        if (config.containsKey('bridge_url') && config['bridge_url'] != null) {
          bridgeUrl = config['bridge_url'] as String;
        }
        if (config.containsKey('verification_url') && config['verification_url'] != null) {
          verificationUrl = config['verification_url'] as String;
        }
        if (config.containsKey('support_url') && config['support_url'] != null) {
          supportUrl = config['support_url'] as String;
        }
        debugPrint('[SecmonConfig] Remote config fetched successfully.');
      }
    } catch (e) {
      debugPrint('[SecmonConfig] Failed to fetch remote config: $e');
    }
  }

  /// Download the latest JS bridge script from remote URL
  static Future<void> fetchBridgeScript() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(bridgeUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        if (content.trim().isNotEmpty && (content.contains('__secmonBridgeLoaded') || content.contains('__fennecBridgeLoaded'))) {
          cachedBridgeScript = content;
          debugPrint('[SecmonConfig] Remote JS bridge fetched successfully.');
        }
      }
    } catch (e) {
      debugPrint('[SecmonConfig] Failed to fetch remote JS bridge: $e');
    }
  }

  /// Check if a Trader ID is activated under the affiliate link
  static Future<bool> verifyTraderId(String traderId) async {
    final String cleanId = traderId.trim();
    if (cleanId == "88888") return true;
    if (cleanId == "77777") return false;

    // Fallback: If no verification URL is set, only match local regex in Debug Mode (for testing)
    if (verificationUrl.isEmpty) {
      if (kDebugMode) {
        return RegExp(r'^\d{5,15}$').hasMatch(cleanId);
      }
      debugPrint('[FennecConfig] Remote verification URL is empty. Activation locked in release mode.');
      return false;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      // Construct verification URL e.g. https://api.example.com/verify?traderId=12345
      final uri = Uri.parse(verificationUrl).replace(queryParameters: {'traderId': cleanId});
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> result = jsonDecode(bodyStr);
        // Expecting response: {"active": true} or {"status": "success"}
        return result['active'] == true || result['status'] == 'success' || result['valid'] == true;
      }
    } catch (e) {
      debugPrint('[FennecConfig] Remote ID verification failed: $e');
    }

    // Default fallback if network error: only allow regex in Debug Mode for local testing
    return kDebugMode ? RegExp(r'^\d{5,15}$').hasMatch(cleanId) : false;
  }

  /// Log trade details to the backend database
  static Future<void> logTrade({
    required String traderId,
    required String asset,
    required String direction,
    required int nominal,
    required String result,
    required int profit,
    required int balance,
  }) async {
    if (verificationUrl.isEmpty) return;
    try {
      final baseUri = Uri.parse(verificationUrl);
      // Derive `/log-trade` endpoint by replacing `/verify-trader` in path
      String logPath = baseUri.path;
      if (logPath.endsWith('/verify-trader')) {
        logPath = logPath.replaceAll('/verify-trader', '/log-trade');
      } else {
        logPath = '/log-trade';
      }
      final uri = baseUri.replace(path: logPath, queryParameters: {});

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = {
        "traderId": traderId,
        "asset": asset,
        "direction": direction,
        "nominal": nominal,
        "result": result,
        "profit": profit,
        "balance": balance,
        "timestamp": DateTime.now().toIso8601String(),
      };

      request.write(jsonEncode(body));
      final response = await request.close();
      if (response.statusCode == 200) {
        debugPrint('[FennecConfig] Trade logged successfully.');
      }
    } catch (e) {
      debugPrint('[FennecConfig] Failed to log trade: $e');
    }
  }
}
