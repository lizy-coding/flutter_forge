package com.flutterforge.preview

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Host-level wiring is limited to app-shell concerns. Module platform
// adapters live in their workspace packages (usb_detector_bridge registers
// usb_detector/usb on its own).
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bluetoothSystem = BluetoothSystemChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_forge/bluetooth_system")
            .setMethodCallHandler { call, result -> bluetoothSystem.handle(call.method, result) }
    }
}
