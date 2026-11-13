package com.flutterforge.forge_notification_bridge

/** One pending Android permission result; all callers run on the main thread. */
internal class PermissionRequest(private val onFinished: () -> Unit) {
    var requestCode: Int = -1
        private set
    private var reply: ((Map<String, Any?>) -> Unit)? = null
    val isActive: Boolean get() = reply != null
    fun begin(code: Int, callback: (Map<String, Any?>) -> Unit): Boolean {
        if (isActive) return false
        requestCode = code
        reply = callback
        return true
    }
    fun complete(code: Int, value: Map<String, Any?>): Boolean {
        if (code != requestCode || !isActive) return false
        interrupt(value)
        return true
    }
    fun interrupt(value: Map<String, Any?>) {
        val callback = reply ?: return
        reply = null
        requestCode = -1
        onFinished()
        callback(value)
    }
}
