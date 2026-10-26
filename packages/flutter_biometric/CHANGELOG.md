## 0.2.0

- Reworked the plugin around a typed bridge contract: platform interface with
  token verification, a never-throwing `queryCapabilities()` and typed
  `BiometricAuthOutcome` results with stable reason codes.
- Android adapter now uses androidx.biometric (`BiometricPrompt` +
  `BiometricManager`), requires the host activity to be a
  `FlutterFragmentActivity`, and reports fingerprint/face availability with
  `FEATURE_FINGERPRINT`/`FEATURE_FACE` hardware checks.
- Added a macOS adapter on LocalAuthentication (Touch ID, credential
  fallback policy).
- Removed the legacy local_auth wrapper, in-app fingerprint management UI and
  camera-based face preview; the plugin now exposes the typed API only.
- Added channel contract tests and typed result tests.
