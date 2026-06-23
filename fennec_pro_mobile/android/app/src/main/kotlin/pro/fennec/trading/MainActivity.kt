package pro.fennec.trading

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.fennecpro/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        ForegroundBotService.startService(this)
                        result.success(null)
                    }
                    "stopService" -> {
                        ForegroundBotService.stopService(this)
                        result.success(null)
                    }
                    "updateNotification" -> {
                        val status = call.argument<String>("status") ?: "Bot aktif..."
                        ForegroundBotService.updateNotification(this, status)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
