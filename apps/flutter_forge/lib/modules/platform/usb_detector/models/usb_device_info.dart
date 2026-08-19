class UsbDeviceInfo {
  final int vendorId;
  final int productId;
  final String? manufacturer;
  final String? product;
  final String? serialNumber;
  final UsbDeviceStatus status;
  final DateTime lastSeen;

  UsbDeviceInfo({
    required this.vendorId,
    required this.productId,
    this.manufacturer,
    this.product,
    this.serialNumber,
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
      '${vendorId.toRadixString(16).padLeft(4, '0')}:${productId.toRadixString(16).padLeft(4, '0')}'
          .toUpperCase();

  @override
  String toString() {
    return 'UsbDeviceInfo(vendorId: $vendorId, productId: $productId, manufacturer: $manufacturer, product: $product, status: $status)';
  }
}

enum UsbDeviceStatus { connected, disconnected, error, unknown }

extension UsbDeviceStatusExtension on UsbDeviceStatus {
  String get displayName {
    switch (this) {
      case UsbDeviceStatus.connected:
        return '已连接';
      case UsbDeviceStatus.disconnected:
        return '已断开';
      case UsbDeviceStatus.error:
        return '错误';
      case UsbDeviceStatus.unknown:
        return '未知';
    }
  }
}
