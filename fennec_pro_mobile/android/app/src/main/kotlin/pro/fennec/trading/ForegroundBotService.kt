package pro.fennec.trading

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Native Android Foreground Service that keeps the Fennec Pro trading bot
 * alive when the app is running in the background.
 *
 * A Foreground Service requires a persistent notification visible to the user.
 * This prevents Android from killing the Flutter engine (and its Dart isolate /
 * Timer.periodic loops) when the app is moved to the background.
 */
class ForegroundBotService : Service() {

    companion object {
        const val CHANNEL_ID     = "fennec_bot_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START   = "START"
        const val ACTION_STOP    = "STOP"
        const val ACTION_UPDATE  = "UPDATE"
        const val EXTRA_STATUS   = "status"

        fun startService(context: Context, status: String = "Monitoring pasar...") {
            val intent = Intent(context, ForegroundBotService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_STATUS, status)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, ForegroundBotService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun updateNotification(context: Context, status: String) {
            val intent = Intent(context, ForegroundBotService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_STATUS, status)
            }
            context.startService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "Monitoring pasar..."
                startForeground(NOTIFICATION_ID, buildNotification(status))
            }
            ACTION_UPDATE -> {
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "Bot aktif..."
                val manager = getSystemService(NotificationManager::class.java)
                manager.notify(NOTIFICATION_ID, buildNotification(status))
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        // START_STICKY: Android restarts this service if it's killed, keeping it alive
        return START_STICKY
    }

    private fun buildNotification(statusText: String): Notification {
        // Tapping the notification opens the app
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("\uD83E\uDD16 Fennec Pro — Bot Aktif")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)          // cannot be dismissed by user swipe
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)           // no sound / vibration
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Fennec Pro Bot",
                NotificationManager.IMPORTANCE_LOW   // low = no sound, no heads-up
            ).apply {
                description = "Trading bot sedang aktif memantau pasar."
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
