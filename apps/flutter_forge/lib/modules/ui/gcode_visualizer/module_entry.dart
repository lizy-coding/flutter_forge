import 'package:material_ui/material_ui.dart';

import 'pages/gcode_visualizer_page.dart'
    if (dart.library.js_interop) 'pages/gcode_visualizer_web_page.dart';

class GcodeVisualizerEntry extends StatelessWidget {
  const GcodeVisualizerEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const GcodeVisualizerPage();
  }
}
