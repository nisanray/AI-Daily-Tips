package com.example.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.*

class NotificationService : Service() {
    companion object {
        private const val TAG = "NotificationService"
        private const val CHANNEL_ID = "daily_tips_channel"
        private const val CHANNEL_NAME = "Daily Tips"
        private const val CHANNEL_DESCRIPTION = "Notification channel for daily tips with actions"
        
        // Method channel for communicating with Flutter
        var methodChannel: MethodChannel? = null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "NotificationService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "NotificationService started")
        
        when (intent?.action) {
            "SHOW_TIP_NOTIFICATION" -> {
                val tipText = intent.getStringExtra("tip_text") ?: ""
                val tipId = intent.getStringExtra("tip_id") ?: ""
                val notificationId = intent.getIntExtra("notification_id", 0)
                showTipNotification(tipText, tipId, notificationId)
            }
            "UPDATE_NOTIFICATION" -> {
                val tipText = intent.getStringExtra("tip_text") ?: ""
                val tipId = intent.getStringExtra("tip_id") ?: ""
                val notificationId = intent.getIntExtra("notification_id", 0)
                updateTipNotification(tipText, tipId, notificationId)
            }
            "CANCEL_NOTIFICATION" -> {
                val notificationId = intent.getIntExtra("notification_id", 0)
                cancelNotification(notificationId)
            }
        }
        
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showTipNotification(tipText: String, tipId: String, notificationId: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create action intents
        val readIntent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_TIP_READ
            putExtra("tip_text", tipText)
            putExtra("tip_id", tipId)
            putExtra("notification_id", notificationId)
        }
        
        val shareIntent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_TIP_SHARE
            putExtra("tip_text", tipText)
            putExtra("tip_id", tipId)
        }
        
        val saveIntent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_TIP_SAVE
            putExtra("tip_text", tipText)
            putExtra("tip_id", tipId)
        }
        
        val dismissIntent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_TIP_DISMISS
            putExtra("tip_id", tipId)
            putExtra("notification_id", notificationId)
        }

        // Create pending intents with unique request codes
        val readPendingIntent = PendingIntent.getBroadcast(
            this, 
            notificationId * 10 + 1, 
            readIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val sharePendingIntent = PendingIntent.getBroadcast(
            this, 
            notificationId * 10 + 2, 
            shareIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val savePendingIntent = PendingIntent.getBroadcast(
            this, 
            notificationId * 10 + 3, 
            saveIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this, 
            notificationId * 10 + 4, 
            dismissIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Your Daily Tip")
            .setContentText(tipText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(tipText))
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setOngoing(false)
            .addAction(android.R.drawable.ic_menu_view, "Read", readPendingIntent)
            .addAction(android.R.drawable.ic_menu_share, "Share", sharePendingIntent)
            .addAction(android.R.drawable.ic_menu_save, "Save", savePendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
        
        // Send data to Flutter
        methodChannel?.invokeMethod("onNotificationShown", mapOf(
            "tipId" to tipId,
            "notificationId" to notificationId,
            "tipText" to tipText
        ))
        
        Log.d(TAG, "Tip notification shown: $tipId")
    }

    private fun updateTipNotification(tipText: String, tipId: String, notificationId: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create updated notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Your Daily Tip (Updated)")
            .setContentText(tipText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(tipText))
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(notificationId, notification)
        
        Log.d(TAG, "Tip notification updated: $tipId")
    }

    private fun cancelNotification(notificationId: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
        
        Log.d(TAG, "Tip notification cancelled: $notificationId")
    }
} 