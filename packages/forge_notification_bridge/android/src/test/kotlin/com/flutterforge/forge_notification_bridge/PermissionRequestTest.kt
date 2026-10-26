package com.flutterforge.forge_notification_bridge
import org.junit.Assert.*
import org.junit.Test
class PermissionRequestTest {
    @Test fun detachOrTimeoutCompletesOnceAndReleasesOwner() {
        var cleanups = 0
        val values = mutableListOf<Map<String, Any?>>()
        val pending = PermissionRequest { cleanups++ }
        assertTrue(pending.begin(5001) { values.add(it) })
        assertFalse(pending.begin(5002) { fail("busy callback must not be registered") })
        pending.interrupt(mapOf("reason" to "activity_detached"))
        pending.interrupt(mapOf("reason" to "permission_timeout"))
        assertFalse(pending.isActive)
        assertEquals(1, cleanups)
        assertEquals(1, values.size)
        assertTrue(pending.begin(5002) { values.add(it) })
        assertFalse(pending.complete(5001, mapOf("status" to "available")))
        assertTrue(pending.isActive)
        assertTrue(pending.complete(5002, mapOf("status" to "available")))
        assertEquals(2, values.size)
        assertEquals(2, cleanups)
    }
}
