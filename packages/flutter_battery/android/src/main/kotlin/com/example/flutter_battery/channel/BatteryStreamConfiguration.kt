package com.example.flutter_battery.channel

// Parse every field before changing any active sampler.
data class BatteryStreamConfiguration(
    val level: Boolean = true,
    val info: Boolean = false,
    val health: Boolean = false,
    val levelInterval: Long = 1000,
    val infoInterval: Long = 5000,
    val healthInterval: Long = 10000,
    val debounce: Boolean = true
) {
    companion object {
        fun from(arguments: Any?): BatteryStreamConfiguration {
            val args = arguments as? Map<*, *> ?: throw IllegalArgumentException("Expected stream configuration")
            fun flag(key: String): Boolean = args[key] as? Boolean ?: throw IllegalArgumentException(key)
            fun interval(key: String): Long {
                val value = (args[key] as? Number)?.toLong() ?: throw IllegalArgumentException(key)
                require(value in 100..3600000) { "Invalid $key" }
                return value
            }
            return BatteryStreamConfiguration(
                flag("monitorBatteryLevel"), flag("monitorBatteryInfo"), flag("monitorBatteryHealth"),
                interval("intervalMs"), interval("batteryInfoIntervalMs"), interval("batteryHealthIntervalMs"),
                flag("enableDebounce")
            )
        }
    }
}
