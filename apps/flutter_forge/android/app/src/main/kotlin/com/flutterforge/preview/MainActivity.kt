package com.flutterforge.preview

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "usb_detector/usb"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listDevices" -> result.success(listUsbDevices())
                else -> result.notImplemented()
            }
        }
    }

    private fun listUsbDevices(): List<Map<String, Any?>> {
        val manager = getSystemService(Context.USB_SERVICE) as? UsbManager
            ?: return emptyList()

        // Enumerating deviceList does not require user permission.  Individual
        // descriptors (notably serialNumber) may still throw until permission
        // has been granted, so never let one device hide the rest.
        return runCatching { manager.deviceList.entries.toList() }
            .getOrElse { emptyList() }
            .mapNotNull { (name, device) -> device.toSafeMap(name, manager) }
    }

    private fun UsbDevice.toSafeMap(name: String, manager: UsbManager): Map<String, Any?>? {
        return runCatching {
            mapOf(
                "id" to name,
                "name" to name,
                "vendorId" to vendorId,
                "productId" to productId,
                "manufacturer" to runCatching { manufacturerName }.getOrNull(),
                "product" to runCatching { productName }.getOrNull(),
                "serialNumber" to if (manager.hasPermission(this)) {
                    runCatching { serialNumber }.getOrNull()
                } else null,
                "hasPermission" to manager.hasPermission(this),
            )
        }.getOrNull()
    }
}
