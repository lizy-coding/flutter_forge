package com.example.flutter_biometric
import org.junit.Test
import org.junit.Assert.*
class AuthenticationReplyTest {
    @Test fun credentialAndBiometricConstantsAreNotReversed() {
        assertEquals("deviceCredential", authenticationMethod(1))
        assertEquals("biometric", authenticationMethod(2))
        assertEquals("unknown", authenticationMethod(-1))
    }
    @Test fun cancelledOrDetachedResultCannotBeOverwrittenByLateSuccess() {
        val values = mutableListOf<Map<String, Any?>>()
        val reply = AuthenticationReply { values.add(it) }
        reply.complete(mapOf("status" to "systemCancel"))
        reply.complete(mapOf("status" to "authenticated"))
        assertEquals(listOf(mapOf("status" to "systemCancel")), values)
        val next = AuthenticationReply { values.add(it) }
        next.complete(mapOf("status" to "authenticated"))
        assertEquals(2, values.size)
    }
}
