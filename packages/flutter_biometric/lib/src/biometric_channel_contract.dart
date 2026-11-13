/// Channel contract shared by the Dart adapter, the Android plugin and the
/// macOS plugin. Keep every string in sync with all native adapters.
abstract final class BiometricChannelContract {
  static const String methodChannel = 'flutter_biometric/auth';

  static const String queryCapabilities = 'queryCapabilities';
  static const String authenticate = 'authenticate';
  static const String cancel = 'cancel';
  static const String argOperationId = 'operationId';
  static const String keyAuthenticationMethod = 'authenticationMethod';

  static const String argReason = 'reason';
  static const String argStrength = 'strength';
  static const String argTitle = 'title';
  static const String argSubtitle = 'subtitle';
  static const String argNegativeLabel = 'negativeLabel';

  static const String keyDeviceSupported = 'deviceSupported';
  static const String keyFingerprintAvailable = 'fingerprintAvailable';
  static const String keyFaceAvailable = 'faceAvailable';
  static const String keyDeviceCredentialAvailable =
      'deviceCredentialAvailable';
  static const String keyEnrolledTypes = 'enrolledTypes';

  static const String keyStatus = 'status';
  static const String keyReason = 'reason';
  static const String keyMessage = 'message';
  static const String keyUsedDeviceCredential = 'usedDeviceCredential';
}
