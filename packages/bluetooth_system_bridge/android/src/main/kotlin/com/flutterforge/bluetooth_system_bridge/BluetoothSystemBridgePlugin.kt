package com.flutterforge.bluetooth_system_bridge
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
class BluetoothSystemBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var system: BluetoothSystemChannel? = null
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_forge/bluetooth_system").also { it.setMethodCallHandler(this) }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        system?.close(); system = null
        channel?.setMethodCallHandler(null); channel = null
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { system = BluetoothSystemChannel(binding.activity) }
    override fun onDetachedFromActivityForConfigChanges() { system?.close(); system = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { onAttachedToActivity(binding) }
    override fun onDetachedFromActivity() { system?.close(); system = null }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val current = system
        if (current == null) result.error("activity_unavailable", "No Activity attached", null)
        else current.handle(call.method, result)
    }
}
