package com.example.flutter_battery.channel

import android.content.Context
import android.os.Build
import androidx.core.content.ContextCompat
import com.example.flutter_battery.ble.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class BleMethodHandler(
    private val context: Context,
    private val bleManager: BleManager,
    private val gattServerManager: GattServerManager,
    private val gattClientManager: GattClientManager
) : PeerStateListener {
    private var peerEventChannelHandler: PeerEventChannelHandler? = null
    init {
        gattServerManager.setPeerStateListener(this)
        gattClientManager.setPeerStateListener(this)
    }
    fun setPeerEventChannelHandler(handler: PeerEventChannelHandler) {
        peerEventChannelHandler = handler
    }
    override fun onPeerState(state: PeerState) {
        peerEventChannelHandler?.sendPeerState(state)
    }
    fun handle(call: MethodCall, result: Result): Boolean {
        when (call.method) {
                "isBleAvailable" -> result.success(bleManager.isBleAvailable())
                "isBleEnabled" -> result.success(bleManager.isBleEnabled())
                "startScan" -> {
                    if (!ensureBlePermissions(result)) return true
                    val args = call.arguments as? Map<*, *>
                    val serviceUuid = args?.get("serviceUuid") as? String
                    bleManager.startScan(serviceUuid)
                    result.success(null)
                }
                "stopScan" -> {
                    bleManager.stopScan()
                    result.success(null)
                }
                "connect" -> {
                    if (!ensureBlePermissions(result)) return true
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    val autoConnect = (args?.get("autoConnect") as? Boolean) ?: false
                    if (deviceId == null) {
                        result.error("INVALID_ARGS", "deviceId is required", null)
                    } else {
                        bleManager.connect(deviceId, autoConnect)
                        result.success(null)
                    }
                }
                "disconnect" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    bleManager.disconnect(deviceId)
                    result.success(null)
                }
                "writeCharacteristic" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    val serviceUuid = args?.get("serviceUuid") as? String
                    val characteristicUuid = args?.get("characteristicUuid") as? String
                    @Suppress("UNCHECKED_CAST")
                    val valueList = args?.get("value") as? List<Number>
                    val withResponse = (args?.get("withResponse") as? Boolean) ?: true

                    if (deviceId == null || serviceUuid == null || characteristicUuid == null || valueList == null) {
                        result.error("INVALID_ARGS", "deviceId, serviceUuid, characteristicUuid, value are required", null)
                    } else {
                        val byteArray = ByteArray(valueList.size) { i -> valueList[i].toByte() }
                        val success = bleManager.writeCharacteristic(
                            deviceId = deviceId,
                            serviceUuid = serviceUuid,
                            characteristicUuid = characteristicUuid,
                            value = byteArray,
                            withResponse = withResponse
                        )
                        result.success(success)
                    }
                }
                "startSlaveMode" -> {
                    if (!ensureBlePermissions(result)) return true
                    gattClientManager.stopMasterMode()
                    gattServerManager.startSlaveMode()
                    result.success(null)
                }
                "stopSlaveMode" -> {
                    gattServerManager.stopSlaveMode()
                    result.success(null)
                }
                "startMasterMode" -> {
                    if (!ensureBlePermissions(result)) return true
                    gattServerManager.stopSlaveMode()
                    gattClientManager.startMasterMode()
                    result.success(null)
                }
                "stopMasterMode" -> {
                    gattClientManager.stopMasterMode()
                    result.success(null)
                }
                "masterConnectToDevice" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    if (deviceId.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "deviceId is required", null)
                    } else {
                        gattClientManager.connectToSlave(deviceId)
                        result.success(null)
                    }
                }
                "stopAllPeerModes" -> {
                    gattClientManager.stopMasterMode()
                    gattServerManager.stopSlaveMode()
                    result.success(null)
                }
            "subscribeToCharacteristic", "unsubscribeFromCharacteristic" ->
                result.error("NOT_SUPPORTED", "BLE characteristic notifications are not implemented", null)
            else -> return false
        }
        return true
    }
    private fun ensureBlePermissions(result: Result): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) listOf(
            android.Manifest.permission.BLUETOOTH_SCAN,
            android.Manifest.permission.BLUETOOTH_CONNECT,
            android.Manifest.permission.BLUETOOTH_ADVERTISE
        ) else listOf(android.Manifest.permission.ACCESS_FINE_LOCATION)
        if (permissions.all { ContextCompat.checkSelfPermission(context, it) == android.content.pm.PackageManager.PERMISSION_GRANTED }) return true
        result.error("PERMISSION_DENIED", "The host must grant BLE permissions before this operation", null)
        return false
    }
    fun dispose() {
        peerEventChannelHandler = null
        gattClientManager.setPeerStateListener(null)
        gattServerManager.setPeerStateListener(null)
        try { gattClientManager.stopMasterMode() } catch (_: Exception) {}
        try { gattServerManager.stopSlaveMode() } catch (_: Exception) {}
        bleManager.dispose()
    }
}
