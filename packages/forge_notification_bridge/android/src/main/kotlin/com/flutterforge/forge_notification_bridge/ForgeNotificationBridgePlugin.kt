package com.flutterforge.forge_notification_bridge

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Local notification adapter over the forge_notification/notifications
 * channel. Permission requests round-trip through the host activity's
 * result callback; every reply is a typed status map, never a channel error.
 */
class ForgeNotificationBridgePlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "forge_notification/notifications",
        ).also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(permissionListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(permissionListener)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(permissionListener)
        activityBinding = null
        pendingPermissionResult = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryCapabilities" -> result.success(queryCapabilities())
            "queryPermissionState" -> result.success(queryPermissionState())
            "requestPermission" -> requestPermission(result)
            "post" -> result.success(post(call))
            "cancel" -> result.success(cancel(call))
            else -> result.notImplemented()
        }
    }

    private val permissionListener =
        PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode != REQUEST_POST_NOTIFICATIONS) return@RequestPermissionsResultListener false
            val pending = pendingPermissionResult
            pendingPermissionResult = null
            if (pending != null) {
                pending.success(
                    permissionMap(
                        if (grantResults.isNotEmpty() &&
                            grantResults[0] == PackageManager.PERMISSION_GRANTED
                        ) "granted" else "denied",
                    )
                )
            }
            true
        }

    private fun queryCapabilities(): Map<String, Any?> = mapOf(
        "postingSupported" to true,
        "permissionQuerySupported" to true,
        // infix `to` binds tighter than >=, so the comparison needs parens.
        "permissionRequestSupported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU),
        "cancelSupported" to true,
    )

    private fun notificationsEnabled(): Boolean {
        val manager =
            appContext?.getSystemService(NotificationManager::class.java) ?: return false
        // areNotificationsEnabled is public since API 24; API 23 devices keep
        // the system default (enabled).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return manager.areNotificationsEnabled()
        }
        return true
    }

    private fun hasRuntimePermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        val context = appContext ?: return false
        return context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun queryPermissionState(): Map<String, Any?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return permissionMap(if (hasRuntimePermission()) "granted" else "denied")
        }
        return permissionMap(if (notificationsEnabled()) "granted" else "denied")
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(permissionMap(if (notificationsEnabled()) "granted" else "denied"))
            return
        }
        if (hasRuntimePermission()) {
            result.success(permissionMap("granted"))
            return
        }
        val binding = activityBinding
        val activity = binding?.activity
        if (activity == null) {
            result.success(unavailable("activity_unavailable", "当前没有可用的 Activity"))
            return
        }
        if (pendingPermissionResult != null) {
            result.success(unavailable("request_in_progress", "已有授权请求进行中"))
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_POST_NOTIFICATIONS,
        )
    }

    private fun post(call: MethodCall): Map<String, Any?> {
        val context = appContext
            ?: return unavailable("context_unavailable", "插件上下文不可用")
        val title = call.argument<String>("title")
        val body = call.argument<String>("body")
        if (title.isNullOrBlank() || body.isNullOrBlank()) {
            return invalidData("missing_content", "标题与内容不能为空")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasRuntimePermission()) {
            return mapOf(
                "status" to "permissionDenied",
                "reason" to "post_notifications_denied",
                "message" to "系统未授予通知权限",
            )
        }
        if (!notificationsEnabled()) {
            return mapOf(
                "status" to "permissionDenied",
                "reason" to "notifications_disabled",
                "message" to "应用通知已被系统关闭",
            )
        }

        val manager = context.getSystemService(NotificationManager::class.java)
            ?: return unavailable("manager_unavailable", "NotificationManager 不可用")
        ensureChannel(manager)

        val id = System.currentTimeMillis().toString()
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.forge_notification_icon)
            .setAutoCancel(true)

        return runCatching {
            manager.notify(id.hashCode(), builder.build())
            mapOf("status" to "available", "notificationId" to id)
        }.getOrElse {
            mapOf(
                "status" to "failed",
                "reason" to "post_failed",
                "message" to (it.message ?: "通知投递失败"),
            )
        }
    }

    private fun cancel(call: MethodCall): Map<String, Any?> {
        val manager = appContext?.getSystemService(NotificationManager::class.java)
            ?: return unavailable("manager_unavailable", "NotificationManager 不可用")
        val id = call.argument<String>("notificationId")
        if (id.isNullOrBlank()) {
            return invalidData("missing_id", "通知标识不能为空")
        }
        manager.cancel(id.hashCode())
        return mapOf("status" to "available", "cancelled" to true)
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "教学通知",
                NotificationManager.IMPORTANCE_DEFAULT,
            )
        )
    }

    private fun permissionMap(state: String): Map<String, Any?> = mapOf(
        "status" to "available",
        "state" to state,
    )

    private fun unavailable(reason: String, message: String): Map<String, Any?> = mapOf(
        "status" to "unavailable",
        "reason" to reason,
        "message" to message,
    )

    private fun invalidData(reason: String, message: String): Map<String, Any?> = mapOf(
        "status" to "invalidData",
        "reason" to reason,
        "message" to message,
    )

    private companion object {
        const val CHANNEL_ID = "forge_general"
        const val REQUEST_POST_NOTIFICATIONS = 4711
    }
}
