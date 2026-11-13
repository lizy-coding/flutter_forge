/// One enumerated USB device as reported by the host adapter.
///
/// Descriptors other than identifiers may be withheld by the OS until the
/// user grants permission; they stay nullable instead of failing the entry.
class UsbDeviceInfo {
  final int vendorId;
  final int productId;
  final String? manufacturer;
  final String? product;
  final String? serialNumber;
  final bool? hasPermission;
  final String? platformDeviceId;
  final String? bus;
  final String? port;
  final UsbDeviceStatus status;
  final DateTime lastSeen;

  UsbDeviceInfo({
    required this.vendorId,
    required this.productId,
    this.manufacturer,
    this.product,
    this.serialNumber,
    this.hasPermission,
    this.platformDeviceId,
    this.bus,
    this.port,
    this.status = UsbDeviceStatus.connected,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  String get displayName {
    if (product != null && product!.isNotEmpty) {
      return product!;
    }
    if (manufacturer != null && manufacturer!.isNotEmpty) {
      return '$manufacturer Device';
    }
    return 'USB Device (${vendorId.toRadixString(16).toUpperCase()}:${productId.toRadixString(16).toUpperCase()})';
  }

  String get deviceId =>
      platformDeviceId ??
      '${vendorId.toRadixString(16).padLeft(4, '0')}:${productId.toRadixString(16).padLeft(4, '0')}'
          .toUpperCase();

  @override
  String toString() {
    return 'UsbDeviceInfo(vendorId: $vendorId, productId: $productId, manufacturer: $manufacturer, product: $product, status: $status)';
  }
}

/// Per-entry runtime state; a malformed payload degrades one entry to
/// [UsbDeviceStatus.error] instead of hiding the remaining devices.
enum UsbDeviceStatus { connected, disconnected, error, unknown }
