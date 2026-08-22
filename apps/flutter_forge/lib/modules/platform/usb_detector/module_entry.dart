import 'package:flutter/material.dart';

import 'module_root.dart' as usb_detector;

class UsbDetectorEntry extends StatelessWidget {
  const UsbDetectorEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const usb_detector.MyHomePage(title: 'USB设备检测器');
  }
}
