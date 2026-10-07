package com.example.flutter_battery.core

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.example.push_notification.PushNotificationManager
import io.flutter.plugin.common.MethodChannel.Result

// Permission prompts and retry decisions belong to the host application.
class NotificationHelper(private val context: Context) {
    fun showNotification(title: String, message: String, result: Result) =
        perform(result) { PushNotificationManager.showNotification(context, title, message) }

    fun scheduleNotification(title: String, message: String, delayMinutes: Int, result: Result) {
        if (delayMinutes < 1) {
            result.error("INVALID_ARGS", "delayMinutes must be positive", null)
            return
        }
        perform(result) { PushNotificationManager.scheduleNotification(context, title, message, delayMinutes) }
    }

    private fun perform(result: Result, operation: () -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "The host must grant notification permission", null)
            return
        }
        try {
            operation()
            result.success(true)
        } catch (error: Exception) {
            result.error("NOTIFICATION_ERROR", error.message, null)
        }
    }
    fun dispose() {}
}
