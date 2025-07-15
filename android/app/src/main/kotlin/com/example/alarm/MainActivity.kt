package com.example.alarm

import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_NAME = "com.example.alarm/notifications"
    }
    
    private lateinit var methodChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity created")
        
        // Removed: dynamic registration of notificationReceiver
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        
        // Set up method channel handlers
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNativeNotification" -> {
                    val tipText = call.argument<String>("tipText") ?: ""
                    val tipId = call.argument<String>("tipId") ?: ""
                    val notificationId = call.argument<Int>("notificationId") ?: 0
                    
                    showNativeNotification(tipText, tipId, notificationId)
                    result.success(null)
                }
                "updateNativeNotification" -> {
                    val tipText = call.argument<String>("tipText") ?: ""
                    val tipId = call.argument<String>("tipId") ?: ""
                    val notificationId = call.argument<Int>("notificationId") ?: 0
                    
                    updateNativeNotification(tipText, tipId, notificationId)
                    result.success(null)
                }
                "cancelNativeNotification" -> {
                    val notificationId = call.argument<Int>("notificationId") ?: 0
                    
                    cancelNativeNotification(notificationId)
                    result.success(null)
                }
                "getNotificationSettings" -> {
                    val settings = getNotificationSettings()
                    result.success(settings)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up notification receiver and service method channels
        NotificationReceiver.methodChannel = methodChannel
        NotificationService.methodChannel = methodChannel
        
        Log.d(TAG, "Flutter engine configured with notification channel")
    }
    
    private fun showNativeNotification(tipText: String, tipId: String, notificationId: Int) {
        val intent = Intent(this, NotificationService::class.java).apply {
            action = "SHOW_TIP_NOTIFICATION"
            putExtra("tip_text", tipText)
            putExtra("tip_id", tipId)
            putExtra("notification_id", notificationId)
        }
        startService(intent)
    }
    
    private fun updateNativeNotification(tipText: String, tipId: String, notificationId: Int) {
        val intent = Intent(this, NotificationService::class.java).apply {
            action = "UPDATE_NOTIFICATION"
            putExtra("tip_text", tipText)
            putExtra("tip_id", tipId)
            putExtra("notification_id", notificationId)
        }
        startService(intent)
    }
    
    private fun cancelNativeNotification(notificationId: Int) {
        val intent = Intent(this, NotificationService::class.java).apply {
            action = "CANCEL_NOTIFICATION"
            putExtra("notification_id", notificationId)
        }
        startService(intent)
    }
    
    private fun getNotificationSettings(): Map<String, Any> {
        return mapOf(
            "hasNotificationPermission" to true, // You can add actual permission check here
            "canScheduleExactAlarms" to true,   // You can add actual alarm permission check here
            "notificationChannelEnabled" to true
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        // Removed: unregisterReceiver(notificationReceiver)
    }
}
