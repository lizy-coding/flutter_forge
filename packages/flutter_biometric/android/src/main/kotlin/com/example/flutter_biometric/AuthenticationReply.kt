package com.example.flutter_biometric
import androidx.biometric.BiometricPrompt

internal fun authenticationMethod(type: Int): String = when (type) {
    BiometricPrompt.AUTHENTICATION_RESULT_TYPE_DEVICE_CREDENTIAL -> "deviceCredential"
    BiometricPrompt.AUTHENTICATION_RESULT_TYPE_BIOMETRIC -> "biometric"
    else -> "unknown"
}

internal class AuthenticationReply(private val reply: (Map<String, Any?>) -> Unit) {
    private var completed = false
    fun complete(value: Map<String, Any?>) {
        if (completed) return
        completed = true
        reply(value)
    }
}
