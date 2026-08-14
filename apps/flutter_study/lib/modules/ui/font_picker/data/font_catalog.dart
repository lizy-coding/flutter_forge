import 'package:flutter/material.dart';

import '../models/font_option.dart';

class FontCatalog {
  const FontCatalog._();

  static List<FontOption> fontsFor(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.macOS => macosFonts,
      TargetPlatform.windows => windowsFonts,
      _ => fallbackFonts,
    };
  }

  static const List<FontOption> macosFonts = [
    FontOption(id: 'pingfang', displayName: '苹方', family: 'PingFang SC'),
    FontOption(
      id: 'pingfang-bold',
      displayName: '苹方',
      family: 'PingFang SC',
      weight: FontWeight.w700,
      styleLabel: '粗体',
    ),
    FontOption(id: 'songti', displayName: '宋体', family: 'Songti SC'),
    FontOption(
      id: 'kaiti-italic',
      displayName: '楷体',
      family: 'Kaiti SC',
      style: FontStyle.italic,
      styleLabel: '斜体',
    ),
    FontOption(id: 'heiti', displayName: '黑体', family: 'Heiti SC'),
    FontOption(id: 'times', displayName: 'Times', family: 'Times New Roman'),
    FontOption(id: 'georgia', displayName: 'Georgia', family: 'Georgia'),
    FontOption(
      id: 'helvetica',
      displayName: 'Helvetica',
      family: 'Helvetica Neue',
    ),
    FontOption(id: 'arial', displayName: 'Arial', family: 'Arial'),
    FontOption(id: 'monaco', displayName: 'Monaco', family: 'Monaco'),
    FontOption(id: 'menlo', displayName: 'Menlo', family: 'Menlo'),
    FontOption(id: 'courier', displayName: 'Courier', family: 'Courier New'),
    FontOption(id: 'zapfino', displayName: 'Zapfino', family: 'Zapfino'),
  ];

  static const List<FontOption> windowsFonts = [
    FontOption(id: 'yahei', displayName: '微软雅黑', family: 'Microsoft YaHei'),
    FontOption(id: 'simsun', displayName: '宋体', family: 'SimSun'),
    FontOption(id: 'simhei', displayName: '黑体', family: 'SimHei'),
    FontOption(id: 'kaiti', displayName: '楷体', family: 'KaiTi'),
    FontOption(id: 'segoe', displayName: 'Segoe UI', family: 'Segoe UI'),
    FontOption(id: 'arial', displayName: 'Arial', family: 'Arial'),
    FontOption(id: 'times', displayName: 'Times', family: 'Times New Roman'),
    FontOption(id: 'consolas', displayName: 'Consolas', family: 'Consolas'),
    FontOption(id: 'courier', displayName: 'Courier', family: 'Courier New'),
  ];

  static const List<FontOption> fallbackFonts = [
    FontOption(id: 'default', displayName: '系统默认', family: 'sans-serif'),
    FontOption(id: 'serif', displayName: 'Serif', family: 'serif'),
    FontOption(id: 'monospace', displayName: 'Monospace', family: 'monospace'),
    FontOption(
      id: 'sans-bold',
      displayName: 'Sans Serif',
      family: 'sans-serif',
      weight: FontWeight.w700,
      styleLabel: '粗体',
    ),
  ];
}
