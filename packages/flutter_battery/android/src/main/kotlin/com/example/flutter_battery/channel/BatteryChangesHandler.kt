package com.example.flutter_battery.channel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.example.flutter_battery.core.BatteryMonitor
import io.flutter.plugin.common.EventChannel

// Broadcast events, independent of the sampling TimerManagers.
class BatteryChangesHandler(private val context: Context, private val monitor: BatteryMonitor) : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var registered = false
    private var samples = emptyList<String>()
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { emit() }
    }
    fun configure(arguments: Any?): Boolean {
        val args = arguments as? Map<*, *> ?: return false
        val level = args["monitorBatteryLevel"] as? Boolean ?: return false
        val info = args["monitorBatteryInfo"] as? Boolean ?: return false
        val health = args["monitorBatteryHealth"] as? Boolean ?: return false
        samples = listOf(level to "level", info to "info", health to "health").filter { it.first }.map { it.second }
        if (sink != null) emit()
        return true
    }
    private fun emit() {
        val target = sink ?: return
        try {
            for (sample in samples) {
                val payload = HashMap<String, Any>(monitor.readBattery(sample))
                payload["type"] = when (sample) { "info" -> "BATTERY_INFO"; "health" -> "BATTERY_HEALTH"; else -> "BATTERY_LEVEL" }
                target.success(payload)
            }
        } catch (error: Exception) { target.error("BATTERY_OPERATION_FAILED", error.message, null) }
    }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        dispose()
        sink = events
        try {
            ContextCompat.registerReceiver(context, receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED), ContextCompat.RECEIVER_NOT_EXPORTED)
            registered = true
            emit()
        } catch (error: Exception) { sink?.error("UNAVAILABLE", error.message, null); dispose() }
    }
    override fun onCancel(arguments: Any?) { dispose() }
    fun dispose() {
        sink = null
        if (registered) { try { context.unregisterReceiver(receiver) } finally { registered = false } }
    }
}
