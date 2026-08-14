import 'package:flutter/material.dart';

@immutable
class FontOption {
  const FontOption({
    required this.id,
    required this.displayName,
    required this.family,
    this.weight = FontWeight.w400,
    this.style = FontStyle.normal,
    this.letterSpacing,
    this.styleLabel = '常规',
    this.isCustom = false,
  });

  final String id;
  final String displayName;
  final String family;
  final FontWeight weight;
  final FontStyle style;
  final double? letterSpacing;
  final String styleLabel;
  final bool isCustom;

  TextStyle textStyle({double? fontSize}) => TextStyle(
    fontFamily: family,
    fontWeight: weight,
    fontStyle: style,
    letterSpacing: letterSpacing,
    fontSize: fontSize,
  );
}
