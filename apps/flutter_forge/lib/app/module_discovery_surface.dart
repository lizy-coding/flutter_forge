import 'package:flutter/material.dart';

import 'forge_pressable_card.dart';

/// Discovery question surface: a pressable card with externally driven
/// highlight support and no tap of its own. Kept as a thin wrapper so the
/// discovery panels retain their API while card interaction stays unified in
/// [ForgePressableCard].
class DiscoverySurface extends StatelessWidget {
  const DiscoverySurface({
    super.key,
    required this.child,
    this.highlighted = false,
    this.radius = 20,
  });

  final Widget child;
  final bool highlighted;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ForgePressableCard(
      radius: radius,
      highlighted: highlighted,
      child: child,
    );
  }
}
