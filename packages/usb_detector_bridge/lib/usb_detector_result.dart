import 'src/usb_channel_contract.dart';

/// Distinguishes a successful enumeration from absent support and runtime
/// failures; only [UsbDetectionStatus.available] carries a value.
enum UsbDetectionStatus {
  pending,
  available,
  unsupported,
  unavailable,
  invalidData,
  failed,
}

/// A stable, machine-readable reason with a human-readable explanation.
class UsbReason {
  const UsbReason(this.code, this.message);
  final String code;
  final String message;
}

class UsbDetectionOutcome<T> {
  const UsbDetectionOutcome._(this.status, this.value, this.reason);

  factory UsbDetectionOutcome.available(T value) =>
      UsbDetectionOutcome._(UsbDetectionStatus.available, value, null);

  factory UsbDetectionOutcome.state(
    UsbDetectionStatus status,
    String code,
    String message,
  ) {
    if (status == UsbDetectionStatus.available) {
      throw ArgumentError.value(status);
    }
    return UsbDetectionOutcome._(
      status,
      null,
      UsbReason(
        code.trim().isEmpty ? 'unspecified_reason' : code,
        message.trim().isEmpty ? 'No additional detail' : message,
      ),
    );
  }

  final UsbDetectionStatus status;
  final T? value;
  final UsbReason? reason;

  bool get isAvailable => status == UsbDetectionStatus.available;
}

/// Adapter support surface, separate from device presence and permissions.
class UsbDetectionCapabilities {
  const UsbDetectionCapabilities({
    required this.enumerationSupported,
    required this.permissionStateSupported,
  });

  const UsbDetectionCapabilities.none()
    : enumerationSupported = false,
      permissionStateSupported = false;

  factory UsbDetectionCapabilities.fromMap(Map<String, bool> values) =>
      UsbDetectionCapabilities(
        enumerationSupported:
            values[UsbChannelContract.capabilityEnumeration] ?? false,
        permissionStateSupported:
            values[UsbChannelContract.capabilityPermissionState] ?? false,
      );

  final bool enumerationSupported;
  final bool permissionStateSupported;

  bool get isSupported => enumerationSupported;
}
