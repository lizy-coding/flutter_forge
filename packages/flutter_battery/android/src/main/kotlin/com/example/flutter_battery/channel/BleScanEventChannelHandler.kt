package com.example.flutter_battery.channel

import com.example.flutter_battery.ble.BleDevice
import com.example.flutter_battery.ble.BleManager
import io.flutter.plugin.common.EventChannel

class BleScanEventChannelHandler(
    private val manager: () -> BleManager
) : EventChannel.StreamHandler, BleManager.ScanListener {

    private val bleManager get() = manager()
    private var events: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        this.events = events
        bleManager.setScanListener(this)
    }

    override fun onCancel(arguments: Any?) {
        if (events != null) {
            bleManager.setScanListener(null)
            try { bleManager.stopScan() } catch (_: Exception) {}
        }
        events = null
    }

    override fun onDeviceFound(device: BleDevice) {
        events?.success(listOf(device.toMap()))
    }

    override fun onScanError(message: String) {
        events?.error("SCAN_ERROR", message, null)
    }
}
