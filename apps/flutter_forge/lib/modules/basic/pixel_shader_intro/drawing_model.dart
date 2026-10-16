import 'package:flutter/material.dart';

const lessonBlue = Color(0xFF2563EB);

class DrawingRule {
  const DrawingRule({this.width = 200, this.proportional = false})
    : assert(width > 0);

  static const height = 100.0;
  final double width;
  final bool proportional;

  double get blueBoundary => proportional ? width / 2 : 100;

  DrawingSample sample(Offset position) {
    final bounded = Offset(
      position.dx.clamp(0.0, width),
      position.dy.clamp(0.0, height),
    );
    final uv = Offset(bounded.dx / width, bounded.dy / height);
    final blue = proportional ? uv.dx < 0.5 : bounded.dx < 100;
    return DrawingSample(position: bounded, uv: uv, blue: blue);
  }

  DrawingSample sampleFromDisplay(Offset position, Size displaySize) {
    if (displaySize.isEmpty) return sample(Offset.zero);
    return sample(
      Offset(
        position.dx / displaySize.width * width,
        position.dy / displaySize.height * height,
      ),
    );
  }
}

class DrawingSample {
  const DrawingSample({
    required this.position,
    required this.uv,
    required this.blue,
  });

  final Offset position;
  final Offset uv;
  final bool blue;

  Color get color => blue ? lessonBlue : Colors.white;
}
