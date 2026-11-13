package com.flutterforge.usb_detector_bridge

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Enumerates attached USB devices over the usb_detector/usb method channel. */
class UsbDetectorBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "usb_detector/usb").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryCapabilities" -> result.success(
                mapOf(
                    "enumerationSupported" to true,
                    "permissionStateSupported" to true,
                )
            )
            "listDevices" -> result.success(listUsbDevices())
            else -> result.notImplemented()
        }
    }

    private fun listUsbDevices(): List<Map<String, Any?>> {
        val manager = context?.getSystemService(Context.USB_SERVICE) as? UsbManager
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
