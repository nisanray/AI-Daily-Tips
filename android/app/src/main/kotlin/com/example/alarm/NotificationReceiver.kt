package com.example.alarm

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class NotificationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationReceiver"
        const val ACTION_TIP_READ = "com.example.alarm.TIP_READ"
        const val ACTION_TIP_SHARE = "com.example.alarm.TIP_SHARE"
        const val ACTION_TIP_SAVE = "com.example.alarm.TIP_SAVE"
        const val ACTION_TIP_DISMISS = "com.example.alarm.TIP_DISMISS"
        
        // Method channel for communicating with Flutter
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received intent: ${intent.action}")
        
        when (intent.action) {
            ACTION_TIP_READ -> handleTipRead(context, intent)
            ACTION_TIP_SHARE -> handleTipShare(context, intent)
            ACTION_TIP_SAVE -> handleTipSave(context, intent)
            ACTION_TIP_DISMISS -> handleTipDismiss(context, intent)
            else -> Log.w(TAG, "Unknown action: ${intent.action}")
        }
    }

    private fun handleTipRead(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra("notification_id", 0)
        val tipText = intent.getStringExtra("tip_text") ?: ""
        val tipId = intent.getStringExtra("tip_id") ?: ""
        
        Log.d(TAG, "Handling tip read: $tipId")
        
        // Send data to Flutter
        methodChannel?.invokeMethod("onTipRead", mapOf(
            "tipId" to tipId,
            "tipText" to tipText,
            "notificationId" to notificationId
        ))
        
        // Dismiss the notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
    }

    private fun handleTipShare(context: Context, intent: Intent) {
        val tipText = intent.getStringExtra("tip_text") ?: ""
        val tipId = intent.getStringExtra("tip_id") ?: ""
        
        Log.d(TAG, "Handling tip share: $tipId")
        
        // Send data to Flutter
        methodChannel?.invokeMethod("onTipShare", mapOf(
            "tipId" to tipId,
            "tipText" to tipText
        ))
    }

    private fun handleTipSave(context: Context, intent: Intent) {
        val tipText = intent.getStringExtra("tip_text") ?: ""
        val tipId = intent.getStringExtra("tip_id") ?: ""
        
        Log.d(TAG, "Handling tip save: $tipId")
        
        // Send data to Flutter
        methodChannel?.invokeMethod("onTipSave", mapOf(
            "tipId" to tipId,
            "tipText" to tipText
        ))
    }

    private fun handleTipDismiss(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra("notification_id", 0)
        val tipId = intent.getStringExtra("tip_id") ?: ""
        
        Log.d(TAG, "Handling tip dismiss: $tipId")
        
        // Send data to Flutter
        methodChannel?.invokeMethod("onTipDismiss", mapOf(
            "tipId" to tipId,
            "notificationId" to notificationId
        ))
        
        // Dismiss the notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
    }
} 