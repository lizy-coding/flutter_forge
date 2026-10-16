import 'package:flutter/material.dart';

enum TextureSample {
  topLeft('左上', '红色', Offset(0.25, 0.25), Color(0xFFFF0000)),
  topRight('右上', '绿色', Offset(0.75, 0.25), Color(0xFF00FF00)),
  bottomLeft('左下', '蓝色', Offset(0.25, 0.75), Color(0xFF0000FF)),
  bottomRight('右下', '黄色', Offset(0.75, 0.75), Color(0xFFFFFF00));

  const TextureSample(this.location, this.colorName, this.uv, this.color);

  final String location;
  final String colorName;
  final Offset uv;
  final Color color;

  Color outputColor({required bool grayscale}) {
    if (!grayscale) return color;
    final value = ((color.r * 0.299 + color.g * 0.587 + color.b * 0.114) * 255)
        .round();
    return Color.fromARGB(255, value, value, value);
  }
}
