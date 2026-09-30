package com.flutterforge.preview

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

/** Public system settings and connected audio profile queries. */
class BluetoothSystemChannel(private val activity: Activity) {
    fun handle(method: String, result: MethodChannel.Result) {
        when (method) {
            "openSettings" -> try {
                activity.startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                result.success(null)
            } catch (error: Exception) {
                result.error("settings_unavailable", error.message, null)
            }
            "connectedAudioDevices" -> queryAudioDevices(result)
            else -> result.notImplemented()
        }
    }

    private fun queryAudioDevices(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_denied", "Bluetooth connection permission is required", null)
            return
        }
        val adapter = (activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val handler = Handler(Looper.getMainLooper())
        val devices = linkedMapOf<String, MutableMap<String, Any?>>()
        val profileNames = mutableMapOf(BluetoothProfile.A2DP to "音频", BluetoothProfile.HEADSET to "通话")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) profileNames[BluetoothProfile.HEARING_AID] = "助听器"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) profileNames[BluetoothProfile.LE_AUDIO] = "低功耗音频"
        val pending = profileNames.keys.toMutableSet()
        val proxies = mutableMapOf<Int, BluetoothProfile>()
        var completed = false
        lateinit var timeout: Runnable
        fun finish(error: Exception? = null) {
            if (completed) return
            completed = true
            handler.removeCallbacks(timeout)
            proxies.forEach { (profile, proxy) -> adapter.closeProfileProxy(profile, proxy) }
            proxies.clear()
            if (error == null) result.success(devices.values.toList())
            else result.error("profile_query_failed", error.message, null)
        }
        timeout = Runnable { finish(IllegalStateException("Bluetooth audio profile query timed out")) }
        handler.postDelayed(timeout, 4000)
        val listener = object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (completed) {
                    adapter.closeProfileProxy(profile, proxy)
                    return
                }
                proxies[profile] = proxy
                try {
                    proxy.connectedDevices.forEach { device ->
                        val entry = devices.getOrPut(device.address) {
                            mutableMapOf("id" to device.address, "name" to device.name, "profiles" to mutableListOf<String>())
                        }
                        @Suppress("UNCHECKED_CAST")
                        val profiles = entry["profiles"] as MutableList<String>
                        profiles.add(profileNames[profile] ?: "音频")
                    }
                    pending.remove(profile)
                    if (pending.isEmpty()) finish()
                } catch (error: Exception) {
                    finish(error)
                }
            }
            override fun onServiceDisconnected(profile: Int) {
                proxies.remove(profile)?.let { adapter.closeProfileProxy(profile, it) }
                pending.remove(profile)
                if (pending.isEmpty()) finish()
            }
        }
        try {
            pending.toList().forEach { profile ->
                if (!adapter.getProfileProxy(activity, listener, profile)) pending.remove(profile)
            }
            if (pending.isEmpty()) finish()
        } catch (error: Exception) {
            finish(error)
        }
    }
}
