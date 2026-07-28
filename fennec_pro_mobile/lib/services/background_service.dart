import 'package:flutter/services.dart';

/// Manages the Android Foreground Service that keeps the bot alive in background.
///
/// Uses a native MethodChannel to communicate with a lightweight Kotlin
/// ForegroundBotService — no extra Flutter package required.
class BotForegroundService {
  static const _channel = MethodChannel('com.secmonpro/foreground_service');

  /// Initialize — no-op in this implementation (native side handles init)
  static void init() {
    // Nothing needed — service is declared in AndroidManifest.xml
  }

  /// Start the foreground service when bot is activated.
  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (_) {
      // Fail silently — foreground service is a UX enhancement, not critical
    }
  }

  /// Stop the foreground service when bot is deactivated.
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }

  /// Update the notification text shown in the status bar.
  static Future<void> updateNotification({required String status}) async {
    try {
      await _channel.invokeMethod('updateNotification', {'status': status});
    } catch (_) {}
  }

  /// Toggle keeping the screen awake/on.
  static Future<void> keepScreenOn(bool keepOn) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'keepOn': keepOn});
    } catch (_) {}
  }

  /// Launch external URL using System Intent (no pub package required).
  static Future<void> launchUrl(String url) async {
    try {
      await _channel.invokeMethod('launchUrl', {'url': url});
    } catch (_) {}
  }
}
