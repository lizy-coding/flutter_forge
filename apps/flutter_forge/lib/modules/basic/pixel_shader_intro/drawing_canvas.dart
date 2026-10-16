import 'package:flutter/material.dart';

import 'drawing_model.dart';

enum DrawingMethod { rectangle, samples }

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    super.key,
    required this.rule,
    required this.method,
    required this.position,
    required this.onPositionChanged,
  });

  final DrawingRule rule;
  final DrawingMethod method;
  final Offset position;
  final ValueChanged<Offset> onPositionChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Keep the same scale for the 200 and 400 unit canvases, including
      // when a compact window requires the entire experiment to shrink.
      final scale = (constraints.maxWidth / 400).clamp(0.0, 1.0);
      final size = Size(rule.width * scale, DrawingRule.height * scale);
      final selected = rule.sample(position);
      void select(Offset localPosition) => onPositionChanged(
        rule.sampleFromDisplay(localPosition, size).position,
      );
      return Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: '教学画布，选中位置的颜色为${selected.blue ? '蓝色' : '白色'}',
          child: GestureDetector(
            key: const Key('intro-canvas'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => select(details.localPosition),
            onPanStart: (details) => select(details.localPosition),
            onPanUpdate: (details) => select(details.localPosition),
            child: SizedBox.fromSize(
              size: size,
              child: CustomPaint(
                painter: DrawingCanvasPainter(
                  rule: rule,
                  method: method,
                  position: selected.position,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class DrawingCanvasPainter extends CustomPainter {
  DrawingCanvasPainter({
    required this.rule,
    required this.method,
    required this.position,
  });

  final DrawingRule rule;
  final DrawingMethod method;
  final Offset position;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = Colors.white);
    if (method == DrawingMethod.rectangle) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          rule.blueBoundary / rule.width * size.width,
          size.height,
        ),
        Paint()..color = lessonBlue,
      );
    } else {
      // Each cell samples its center. This intentionally enlarged grid is
      // a Dart/Canvas teaching model, not a GPU fragment shader execution.
      final columns = rule.width ~/ 10;
      const rows = 10;
      for (var row = 0; row < rows; row++) {
        for (var column = 0; column < columns; column++) {
          final sample = rule.sample(
            Offset(
              (column + 0.5) / columns * rule.width,
              (row + 0.5) / rows * DrawingRule.height,
            ),
          );
          canvas.drawRect(
            Rect.fromLTWH(
              column / columns * size.width,
              row / rows * size.height,
              size.width / columns,
              size.height / rows,
            ),
            Paint()..color = sample.color,
          );
        }
      }
      final grid = Paint()
        ..color = const Color(0x44000000)
        ..strokeWidth = 0.5;
      for (var column = 1; column < columns; column++) {
        final x = column / columns * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var row = 1; row < rows; row++) {
        final y = row / rows * size.height;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    canvas.drawRect(
      bounds.deflate(0.5),
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke,
    );
    final point = Offset(
      position.dx / rule.width * size.width,
      position.dy / DrawingRule.height * size.height,
    );
    canvas.drawCircle(point, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      point,
      6,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(point, 2, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(DrawingCanvasPainter oldDelegate) =>
      oldDelegate.rule != rule ||
      oldDelegate.method != method ||
      oldDelegate.position != position;
}
