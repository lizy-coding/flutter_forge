package com.example.flutter_biometric

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Biometric authentication adapter over the flutter_biometric/auth channel.
 * Self-registers through FlutterPlugin so the host app keeps only app-shell
 * native code. Every method replies with a typed status map; a missing or
 * non-Fragment activity degrades to `unavailable`, never a channel error.
 */
class FlutterBiometricPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null
    private var activity: FragmentActivity? = null
    private var activePrompt: BiometricPrompt? = null
    private var activeId: String? = null
    private var activeCompletion: ((Map<String, Any?>) -> Unit)? = null

    private fun cancelActive(reason: String) {
        val prompt = activePrompt
        val complete = activeCompletion
        complete?.invoke(mapOf("status" to "systemCancel", "reason" to reason, "message" to "认证操作已中断"))
        prompt?.cancelAuthentication()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flutter_biometric/auth").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cancelActive("engine_detached")
        activity = null
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        cancelActive("activity_detached")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        cancelActive("activity_detached")
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryCapabilities" -> result.success(queryCapabilities())
            "authenticate" -> authenticate(call, result)
            "cancel" -> {
                if (((call.arguments as? Map<*, *>)?.get("operationId") as? String) == activeId) cancelActive("owner_cancelled")
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun queryCapabilities(): Map<String, Any?> {
        val context = appContext ?: return emptyStatus()
        val manager = BiometricManager.from(context)
        val canStrong = canAuthenticate(manager, BiometricManager.Authenticators.BIOMETRIC_STRONG)
        val canWeak = canAuthenticate(manager, BiometricManager.Authenticators.BIOMETRIC_WEAK)
        val canCredential =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                canAuthenticate(manager, BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            } else {
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED
            }

        // FEATURE_FACE distinguishes face hardware from fingerprint-only
        // devices, because BIOMETRIC_WEAK alone also succeeds via fingerprint.
        val fingerprintAvailable = hasFeature(context, PackageManager.FEATURE_FINGERPRINT)
        val faceAvailable = hasFeature(context, PackageManager.FEATURE_FACE)


        val credentialAvailable = canCredential == BiometricManager.BIOMETRIC_SUCCESS
        return mapOf(
            "deviceSupported" to (canWeak == BiometricManager.BIOMETRIC_SUCCESS || credentialAvailable),
            "fingerprintAvailable" to fingerprintAvailable,
            "faceAvailable" to faceAvailable,
            "deviceCredentialAvailable" to credentialAvailable,
            "enrolledTypes" to emptyList<String>(),
            "sensorEnrollmentKnown" to false,
            "strongAvailable" to (canStrong == BiometricManager.BIOMETRIC_SUCCESS),
            "weakAvailable" to (canWeak == BiometricManager.BIOMETRIC_SUCCESS),
        )
    }

    private fun authenticate(call: MethodCall, result: MethodChannel.Result) {
        if (activeId != null) {
            result.success(unavailable("authentication_in_progress", "已有认证进行中"))
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(unavailable("activity_unavailable", "当前没有可用的 FragmentActivity"))
            return
        }
        val reason = ((call.arguments as? Map<*, *>)?.get("reason") as? String)
        if (reason.isNullOrBlank()) {
            result.success(invalidData("missing_reason", "认证原因不能为空"))
            return
        }
        val args = call.arguments as? Map<*, *>
        val invalidField = listOf("strength", "title", "subtitle", "negativeLabel", "operationId").any {
            args?.get(it) != null && args[it] !is String
        }
        val strength = args?.get("strength") as? String ?: "strong"
        if (invalidField || strength !in listOf("strong", "weak", "strongWithCredential") ||
            (args?.get("title") as? String)?.isBlank() == true ||
            (args?.get("negativeLabel") as? String)?.isBlank() == true) {
            result.success(invalidData("invalid_request", "认证请求字段无效"))
            return
        }

        // androidx throws on the platform thread when biometric and device
        // credential authenticators are combined below API 30; degrade to a
        // typed outcome instead of crashing the host app.
        if (strength == "strongWithCredential" &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.R
        ) {
            result.success(
                unavailable(
                    "combination_unsupported",
                    "当前系统版本不支持生物特征与设备凭据组合认证",
                )
            )
            return
        }

        val authenticators = when (strength) {
            "weak" -> BiometricManager.Authenticators.BIOMETRIC_WEAK
            "strongWithCredential" ->
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
            else -> BiometricManager.Authenticators.BIOMETRIC_STRONG
        }

        val builder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(((call.arguments as? Map<*, *>)?.get("title") as? String) ?: "身份验证")
            .setAllowedAuthenticators(authenticators)
        val subtitle = ((call.arguments as? Map<*, *>)?.get("subtitle") as? String)
        if (!subtitle.isNullOrBlank()) builder.setSubtitle(subtitle)
        if (strength != "strongWithCredential") {
            // androidx routes the negative button through the regular error
            // callback (BiometricPrompt.ERROR_NEGATIVE_BUTTON); no listener is exposed.
            builder.setNegativeButtonText(((call.arguments as? Map<*, *>)?.get("negativeLabel") as? String) ?: "取消")
        }

        // Replies complete asynchronously from the prompt callbacks; the
        // platform main thread must stay free for those callbacks.
        val operationId = ((call.arguments as? Map<*, *>)?.get("operationId") as? String) ?: "native/${System.nanoTime()}"
        activeId = operationId
        val terminal = AuthenticationReply { map ->
            if (activeId == operationId) {
                activeId = null
                activePrompt = null
                activeCompletion = null
            }
            result.success(map)
        }
        fun complete(map: Map<String, Any?>) = terminal.complete(map)
        activeCompletion = ::complete
        try {
            val prompt = BiometricPrompt(
                currentActivity,
                ContextCompat.getMainExecutor(currentActivity),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                        val method = authenticationMethod(authResult.authenticationType)
                        complete(mapOf("status" to "authenticated", "authenticationMethod" to method))
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        complete(mapStatus(errorCode, errString.toString()))
                    }
                    // onAuthenticationFailed is a per-attempt mismatch; the prompt
                    // stays up, so the reply waits for success or a final error.
                },
            )
            activePrompt = prompt
            // Some OEM/SDK states reject prompt arguments with a throw instead of
            // routing them through the error callback; keep the channel
            // non-throwing like every other failure path here.
            prompt.authenticate(builder.build())
        } catch (error: IllegalArgumentException) {
            complete(invalidData("prompt_rejected", error.message ?: "系统拒绝了认证参数"))
        } catch (error: IllegalStateException) {
            complete(unavailable("prompt_unavailable", error.message ?: "认证提示不可用"))
        }
    }

    private fun mapStatus(errorCode: Int, message: String): Map<String, Any?> {
        val status = when (errorCode) {
            BiometricPrompt.ERROR_USER_CANCELED, BiometricPrompt.ERROR_NEGATIVE_BUTTON -> "userCancel"
            BiometricPrompt.ERROR_CANCELED -> "systemCancel"
            BiometricPrompt.ERROR_TIMEOUT -> "timeout"
            BiometricPrompt.ERROR_LOCKOUT -> "lockout"
            BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "permanentlyLockedOut"
            BiometricPrompt.ERROR_NO_BIOMETRICS -> "notEnrolled"
            BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> "credentialNotSet"
            BiometricPrompt.ERROR_HW_NOT_PRESENT -> "noHardware"
            BiometricPrompt.ERROR_HW_UNAVAILABLE -> "hardwareUnavailable"
            else -> "failed"
        }
        return mapOf(
            "status" to status,
            "reason" to "android_error_$errorCode",
            "message" to message,
        )
    }

    private fun canAuthenticate(manager: BiometricManager, authenticators: Int): Int =
        runCatching { manager.canAuthenticate(authenticators) }
            .getOrElse { BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE }

    private fun hasFeature(context: Context, feature: String): Boolean =
        context.packageManager.hasSystemFeature(feature)

    private fun emptyStatus(): Map<String, Any?> = mapOf(
        "deviceSupported" to false,
        "fingerprintAvailable" to false,
        "faceAvailable" to false,
        "deviceCredentialAvailable" to false,
        "enrolledTypes" to emptyList<String>(),
    )
}

/** Status helpers mirroring the typed outcome reasons in Dart. */
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
