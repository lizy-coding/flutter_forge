import 'package:material_ui/material_ui.dart';

import 'module_root.dart' as debounce_throttle;

class DebounceThrottleEntry extends StatelessWidget {
  const DebounceThrottleEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const debounce_throttle.MyHomePage(title: '防抖与节流比较');
  }
}
