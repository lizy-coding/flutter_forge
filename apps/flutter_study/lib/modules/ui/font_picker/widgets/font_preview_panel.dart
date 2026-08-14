import 'package:flutter/material.dart';

import '../models/font_option.dart';

class FontPreviewPanel extends StatelessWidget {
  const FontPreviewPanel({
    super.key,
    required this.option,
    this.sampleText = '字体选择器演示 The quick brown fox 0123456789',
  });

  final FontOption? option;
  final String sampleText;

  @override
  Widget build(BuildContext context) {
    final current = option;
    if (current == null) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(20), child: Text('请选择字体')),
      );
    }
    return Card(
      key: const Key('font-preview-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sampleText, style: current.textStyle(fontSize: 24)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(current.displayName)),
                Chip(label: Text(current.family)),
                Chip(label: Text(current.styleLabel)),
                if (current.isCustom) const Chip(label: Text('本地字体')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
