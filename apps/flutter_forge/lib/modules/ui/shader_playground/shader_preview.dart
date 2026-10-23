import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ShaderEffect { solid, split, gradient, sweep }

const _assetRoot = 'lib/modules/ui/shader_playground/shaders';

class ShaderLesson {
  ShaderLesson({required this.shader, required this.source});

  final ui.FragmentShader shader;
  final String source;

  static Future<ShaderLesson> load() async {
    final source = await rootBundle.loadString('$_assetRoot/uv_gradient.glsl');
    final program = await ui.FragmentProgram.fromAsset(
      '$_assetRoot/uv_gradient.frag',
    );
    return ShaderLesson(shader: program.fragmentShader(), source: source);
  }

  void dispose() => shader.dispose();
}

class ShaderParameters {
  const ShaderParameters({
    this.effect = ShaderEffect.gradient,
    this.phase = 0.5,
    this.bandWidth = 0.3,
    this.softness = 0.6,
    this.vertical = false,
    this.showUv = false,
    this.offset = 0,
    this.startColor = const Color(0xFF2563EB),
    this.endColor = const Color(0xFFF97316),
  });

  final ShaderEffect effect;
  final double phase;
  final double bandWidth;
  final double softness;
  final bool vertical;
  final bool showUv;
  final double offset;
  final Color startColor;
  final Color endColor;

  ShaderParameters copyWith({
    ShaderEffect? effect,
    double? phase,
    double? bandWidth,
    double? softness,
    bool? vertical,
    bool? showUv,
    double? offset,
    Color? startColor,
    Color? endColor,
  }) => ShaderParameters(
    effect: effect ?? this.effect,
    phase: phase ?? this.phase,
    bandWidth: bandWidth ?? this.bandWidth,
    softness: softness ?? this.softness,
    vertical: vertical ?? this.vertical,
    showUv: showUv ?? this.showUv,
    offset: offset ?? this.offset,
    startColor: startColor ?? this.startColor,
    endColor: endColor ?? this.endColor,
  );

  double blendAt(Offset uv) {
    if (effect == ShaderEffect.solid) return 0;
    if (effect == ShaderEffect.split) return uv.dx < 0.5 ? 0 : 1;
    if (effect == ShaderEffect.gradient) {
      return ((vertical ? uv.dy : uv.dx) + offset).clamp(0.0, 1.0);
    }
    final center = -bandWidth + (1 + 2 * bandWidth) * phase;
    final distance = (uv.dx - center).abs();
    final inner = bandWidth * (1 - softness);
    final t = ((distance - inner) / (bandWidth - inner)).clamp(0.0, 1.0);
    return 1 - t * t * (3 - 2 * t);
  }

  Color colorAt(Offset uv) => showUv
      ? Color.from(alpha: 1, red: uv.dx, green: uv.dy, blue: 0)
      : Color.lerp(startColor, endColor, blendAt(uv))!;
}

class ShaderPreviewPainter extends CustomPainter {
  ShaderPreviewPainter({required this.shader, required this.parameters});

  final ui.FragmentShader shader;
  final ShaderParameters parameters;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Float slots follow the declarations in uv_gradient.glsl.
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, parameters.vertical ? 1 : 0)
      ..setFloat(3, parameters.showUv ? 1 : 0)
      ..setFloat(4, parameters.offset);
    _writeColor(5, parameters.startColor);
    _writeColor(9, parameters.endColor);
    shader
      ..setFloat(13, parameters.effect.index.toDouble())
      ..setFloat(14, parameters.phase)
      ..setFloat(15, parameters.bandWidth)
      ..setFloat(16, parameters.softness);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _writeColor(int index, Color color) {
    shader
      ..setFloat(index, color.r * color.a)
      ..setFloat(index + 1, color.g * color.a)
      ..setFloat(index + 2, color.b * color.a)
      ..setFloat(index + 3, color.a);
  }

  @override
  bool shouldRepaint(ShaderPreviewPainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.parameters != parameters;
}
