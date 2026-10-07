package com.example.flutter_battery.channel

import com.example.flutter_battery.core.NotificationHelper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class NotificationMethodHandler(private val notificationHelper: NotificationHelper) {
    fun handle(call: MethodCall, result: Result): Boolean {
        when (call.method) {
                "scheduleNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "通知"
                        val message = call.argument<String>("message") ?: "您有一条新消息"
                        val delayMinutes = call.argument<Int>("delayMinutes") ?: 1

                        notificationHelper.scheduleNotification(
                            title,
                            message,
                            delayMinutes,
                            result
                        )
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
                    }
                }
                "showNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "通知"
                        val message = call.argument<String>("message") ?: "您有一条新消息"

                        notificationHelper.showNotification(
                            title,
                            message,
                            result
                        )
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                    }
                }
            else -> return false
        }
        return true
    }
}
