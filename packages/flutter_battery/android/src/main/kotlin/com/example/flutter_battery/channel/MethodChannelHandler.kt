package com.example.flutter_battery.channel

import android.content.Context
import com.example.flutter_battery.ble.*
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.NotificationHelper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MethodChannelHandler(
    context: Context,
    channel: MethodChannel,
    batteryMonitor: BatteryMonitor,
    notificationHelper: NotificationHelper,
    bleManager: () -> BleManager,
    gattServerManager: () -> GattServerManager,
    gattClientManager: () -> GattClientManager
) : MethodChannel.MethodCallHandler {
    private val battery = BatteryMethodHandler(channel, batteryMonitor)
    private val notifications = NotificationMethodHandler(notificationHelper)
    private var peerHandler: PeerEventChannelHandler? = null
    private var createdBle: BleMethodHandler? = null
    private val ble by lazy {
        BleMethodHandler(context, bleManager(), gattServerManager(), gattClientManager()).also {
            createdBle = it
            peerHandler?.let { handler -> it.setPeerEventChannelHandler(handler) }
        }
    }
    private var events: EventChannelHandler? = null

    fun setEventChannelHandler(handler: EventChannelHandler) { events = handler }
    fun setPeerEventChannelHandler(handler: PeerEventChannelHandler) { peerHandler = handler; createdBle?.setPeerEventChannelHandler(handler) }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                "getPlatformCapabilities" -> result.success(mapOf(
                    "scopedObservations" to true, "batteryLevel" to true, "batteryInfo" to true, "batteryHealth" to true,
                    "batteryLevelStream" to true, "batteryInfoStream" to true, "batteryHealthStream" to true,
                    "lowBatteryMonitoring" to true, "nativeNotifications" to true,
                    "scheduledNotifications" to true, "blePeerSync" to true,
                    "bleCharacteristicNotifications" to false, "iotExampleBridge" to false
                ))
                "configureBatteryStream" -> {
                    val config = BatteryStreamConfiguration.from(call.arguments)
                    val handler = events ?: throw IllegalStateException("Battery event handler unavailable")
                    handler.configure(config)
                    result.success(true)
                }
                else -> if (!battery.handle(call, result) && !notifications.handle(call, result) && !ble.handle(call, result)) result.notImplemented()
            }
        } catch (error: IllegalArgumentException) {
            result.error("INVALID_ARGS", error.message, null)
        } catch (error: Exception) {
            result.error("BATTERY_OPERATION_FAILED", error.message, null)
        }
    }
    fun dispose() {
        events = null
        peerHandler = null
        createdBle?.dispose()
    }
}
