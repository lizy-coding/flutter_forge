package com.example.flutter_battery

import android.app.Application
import android.content.Context
import androidx.annotation.NonNull
import com.example.flutter_battery.ble.BleManager
import com.example.flutter_battery.channel.BleConnectionEventChannelHandler
import com.example.flutter_battery.channel.BleScanEventChannelHandler
import com.example.flutter_battery.channel.EventChannelHandler
import com.example.flutter_battery.channel.MethodChannelHandler
import com.example.flutter_battery.channel.PeerEventChannelHandler
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.NotificationHelper
import com.example.flutter_battery.ble.GattClientManager
import com.example.flutter_battery.ble.GattServerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** FlutterBatteryPlugin */
class FlutterBatteryPlugin : FlutterPlugin {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bleMethodChannel: MethodChannel
    private lateinit var bleScanEventChannel: EventChannel
    private lateinit var bleConnectionEventChannel: EventChannel
    private lateinit var peerMethodChannel: MethodChannel
    private lateinit var peerEventChannel: EventChannel
    private lateinit var applicationContext: Context

    // 核心组件
    private lateinit var batteryMonitor: BatteryMonitor
    private lateinit var notificationHelper: NotificationHelper

    // BLE
    private val bleManager by lazy { BleManager(applicationContext) }
    private val peerBleManager by lazy { BleManager(applicationContext) }
    private val gattServerManager by lazy { GattServerManager(applicationContext, batteryMonitor) }
    private val gattClientManager by lazy { GattClientManager(applicationContext, batteryMonitor, peerBleManager) }

    // 通道处理器
    private lateinit var methodChannelHandler: MethodChannelHandler
    private lateinit var eventChannelHandler: EventChannelHandler
    private var bleScanHandler: BleScanEventChannelHandler? = null
    private var bleConnectionHandler: BleConnectionEventChannelHandler? = null
    private var peerEventHandler: PeerEventChannelHandler? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        applicationContext = if (context is Application) context else context.applicationContext

        // 1. 初始化通道
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/battery_stream")

        // 2. 初始化核心组件
        batteryMonitor = BatteryMonitor(applicationContext)
        notificationHelper = NotificationHelper(applicationContext)

        // 3. 初始化通道处理器
        methodChannelHandler = MethodChannelHandler(
            applicationContext,
            methodChannel,
            batteryMonitor,
            notificationHelper,
            { bleManager },
            { gattServerManager },
            { gattClientManager }
        )

        eventChannelHandler = EventChannelHandler(
            applicationContext,
            eventChannel,
            batteryMonitor
        )

        // 设置关联，让 MethodChannelHandler 可以访问 EventChannelHandler
        methodChannelHandler.setEventChannelHandler(eventChannelHandler)

        // 4. 设置方法调用处理器
        methodChannel.setMethodCallHandler(methodChannelHandler)
        eventChannel.setStreamHandler(eventChannelHandler)

        // 5. BLE 通道
        bleMethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/ble_methods")
        bleScanEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/ble_scan_events")
        bleConnectionEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/ble_connection_events")
        peerMethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/peer_methods")
        peerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/peer_events")

        bleScanHandler = BleScanEventChannelHandler { bleManager }
        bleConnectionHandler = BleConnectionEventChannelHandler { bleManager }
        peerEventHandler = PeerEventChannelHandler()

        bleMethodChannel.setMethodCallHandler(methodChannelHandler)
        bleScanEventChannel.setStreamHandler(bleScanHandler)
        bleConnectionEventChannel.setStreamHandler(bleConnectionHandler)
        peerMethodChannel.setMethodCallHandler(methodChannelHandler)
        peerEventChannel.setStreamHandler(peerEventHandler)
        peerEventHandler?.let { methodChannelHandler.setPeerEventChannelHandler(it) }

    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // 释放资源
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        bleMethodChannel.setMethodCallHandler(null)
        bleScanEventChannel.setStreamHandler(null)
        bleConnectionEventChannel.setStreamHandler(null)
        peerMethodChannel.setMethodCallHandler(null)
        peerEventChannel.setStreamHandler(null)

        batteryMonitor.dispose()
        notificationHelper.dispose()
        methodChannelHandler.dispose()
        eventChannelHandler.dispose()
        bleScanHandler = null
        bleConnectionHandler = null
        peerEventHandler = null
    }

}
