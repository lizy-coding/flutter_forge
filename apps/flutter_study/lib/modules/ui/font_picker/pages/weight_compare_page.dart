import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class WeightComparePage extends StatefulWidget {
  const WeightComparePage({super.key});

  @override
  State<WeightComparePage> createState() => _WeightComparePageState();
}

class _WeightComparePageState extends State<WeightComparePage> {
  bool _italic = false;
  double _letterSpacing = 0;

  static const _weights = <(int, FontWeight)>[
    (100, FontWeight.w100),
    (300, FontWeight.w300),
    (400, FontWeight.w400),
    (600, FontWeight.w600),
    (900, FontWeight.w900),
  ];

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '字重与字距对比',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, weight) in _weights)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'w$value  字重对比 Weight',
                key: Key('weight-$value'),
                style: TextStyle(fontSize: 21, fontWeight: weight),
              ),
            ),
          const Divider(),
          SwitchListTile(
            key: const Key('italic-toggle'),
            title: const Text('斜体'),
            value: _italic,
            onChanged: (value) => setState(() => _italic = value),
          ),
          Text('字距：${_letterSpacing.toStringAsFixed(1)}'),
          Slider(
            key: const Key('letter-spacing-slider'),
            min: 0,
            max: 2,
            divisions: 20,
            value: _letterSpacing,
            onChanged: (value) => setState(() => _letterSpacing = value),
          ),
          Text(
            '实时样式 Live preview 0123',
            key: const Key('live-style-preview'),
            style: TextStyle(
              fontSize: 24,
              fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
              letterSpacing: _letterSpacing,
            ),
          ),
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: ['观察不同 FontWeight 的视觉层级', '理解斜体和字距对排版节奏的影响'],
        ),
        ConceptChips(
          concepts: [
            'FontWeight',
            'w100-w900',
            'FontStyle.italic',
            'letterSpacing',
          ],
        ),
      ],
    );
  }
}
