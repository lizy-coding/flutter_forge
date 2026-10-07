package com.example.flutter_battery.channel

import com.example.flutter_battery.core.BatteryMonitor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class BatteryMethodHandler(private val channel: MethodChannel, private val batteryMonitor: BatteryMonitor) {
    init {
        // 设置低电量回调
        batteryMonitor.setOnLowBatteryCallback { batteryLevel ->
            val params = HashMap<String, Any>()
            params["batteryLevel"] = batteryLevel
            channel.invokeMethod("onLowBattery", params)
        }

        // 设置电池电量变化回调
        batteryMonitor.setOnBatteryLevelChangeCallback { batteryLevel ->
            val params = HashMap<String, Any>()
            params["batteryLevel"] = batteryLevel
            channel.invokeMethod("onBatteryLevelChanged", params)
        }

        // 设置电池信息变化回调
        batteryMonitor.setOnBatteryInfoChangeCallback { batteryInfo ->
            channel.invokeMethod("onBatteryInfoChanged", batteryInfo)
        }

        batteryMonitor.setOnBatteryHealthChangeCallback { batteryHealth ->
            channel.invokeMethod("onBatteryHealthChanged", batteryHealth)
        }

    }

    fun handle(call: MethodCall, result: Result): Boolean {
        when (call.method) {
                "getBatteryLevel" -> {
                    try {
                        val batteryLevel = batteryMonitor.getBatteryLevel()
                        result.success(batteryLevel)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "获取电池电量失败: ${e.message}", null)
                    }
                }
                "getBatteryInfo" -> {
                    try {
                        val batteryInfo = batteryMonitor.getBatteryInfo()
                        result.success(batteryInfo)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "获取电池信息失败: ${e.message}", null)
                    }
                }
                "getBatteryHealth" -> {
                    try {
                        val batteryHealth = batteryMonitor.getBatteryHealth()
                        result.success(batteryHealth)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "获取电池健康失败: ${e.message}", null)
                    }
                }
                "getBatteryOptimizationTips" -> {
                    try {
                        val tips = batteryMonitor.getBatteryOptimizationTips()
                        result.success(tips)
                    } catch (e: Exception) {
                        result.error("BATTERY_TIPS_ERROR", "获取电池优化建议失败: ${e.message}", null)
                    }
                }
                "startBatteryLevelListening" -> {
                    try {
                        batteryMonitor.startBatteryLevelListening()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "开始电池电量监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryLevelListening" -> {
                    try {
                        batteryMonitor.stopBatteryLevelListening()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "停止电池电量监听失败: ${e.message}", null)
                    }
                }
                "startBatteryInfoListening" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong() ?: 5000
                        batteryMonitor.startBatteryInfoListening(intervalMs)

                        // 启用事件通道完整电池信息推送


                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "开始电池信息监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryInfoListening" -> {
                    try {
                        batteryMonitor.stopBatteryInfoListening()

                        // 禁用事件通道完整电池信息推送


                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "停止电池信息监听失败: ${e.message}", null)
                    }
                }
                "startBatteryHealthListening" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong()
                            ?: 10_000L
                        batteryMonitor.startBatteryHealthListening(intervalMs)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "开始电池健康监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryHealthListening" -> {
                    try {
                        batteryMonitor.stopBatteryHealthListening()

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "停止电池健康监听失败: ${e.message}", null)
                    }
                }
                "setBatteryLevelThreshold" -> {
                    try {
                        val threshold = call.argument<Int>("threshold") ?: 20
                        val title = call.argument<String>("title") ?: "电池电量低"
                        val message = call.argument<String>("message") ?: "您的电池电量已经低于阈值"
                        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 15
                        val useFlutterRendering = call.argument<Boolean>("useFlutterRendering") ?: false

                        batteryMonitor.startMonitoring(
                            threshold,
                            title,
                            message,
                            intervalMinutes,
                            useFlutterRendering
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_MONITORING_ERROR", "设置电池监控失败: ${e.message}", null)
                    }
                }
                "stopBatteryMonitoring" -> {
                    try {
                        batteryMonitor.stopMonitoring()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_MONITORING_ERROR", "停止电池监控失败: ${e.message}", null)
                    }
                }
                "setPushInterval" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong() ?: 1000
                        val enableDebounce = call.argument<Boolean>("enableDebounce") ?: true

                        // 同时设置两种推送间隔：EventChannel和BatteryMonitor
                        // 1. 更新 EventChannel 推送频率


                        // 2. 更新 BatteryMonitor 推送频率
                        batteryMonitor.setBatteryLevelPushInterval(intervalMs, enableDebounce)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EVENT_CHANNEL_ERROR", "设置推送间隔失败: ${e.message}", null)
                    }
                }
            else -> return false
        }
        return true
    }
}
