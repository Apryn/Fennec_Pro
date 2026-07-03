package pro.fennec.trading

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.content.Intent
import android.net.Uri

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
                    "keepScreenOn" -> {
                        val keepOn = call.argument<Boolean>("keepOn") ?: false
                        if (keepOn) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    "launchUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("LAUNCH_FAILED", e.message, null)
                            }
                        } else {
                            result.error("INVALID_URL", "URL is null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
