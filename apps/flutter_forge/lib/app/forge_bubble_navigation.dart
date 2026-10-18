import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

@immutable
class ForgeNavigationDestination {
  const ForgeNavigationDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ForgeBubbleNavigation extends StatefulWidget {
  const ForgeBubbleNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinationKey,
    this.showLabels = true,
  }) : assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<ForgeNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Key Function(int index) destinationKey;
  final bool showLabels;

  @override
  State<ForgeBubbleNavigation> createState() => _ForgeBubbleNavigationState();
}

class _ForgeBubbleNavigationState extends State<ForgeBubbleNavigation>
    with SingleTickerProviderStateMixin {
  // Use the library's tab-bar travel and deformation tuning on the vertical
  // axis. The app owns position; MotionPill owns the glass and squash/stretch.
  static const _pill = LiquidGlassTabPillStyle();
  static final _spring = SpringDescription(
    mass: 1,
    stiffness: _pill.travelStiffness,
    damping: _pill.travelDamping,
  );

  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.highContrastOf(context);
    if (_reduceMotion) _position.value = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(ForgeBubbleNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == oldWidget.selectedIndex) return;
    final target = widget.selectedIndex.toDouble();
    if (_reduceMotion) {
      _position.value = target;
    } else {
      _position.animateWith(
        SpringSimulation(
          _spring,
          _position.value,
          target,
          _position.velocity,
          tolerance: const Tolerance(distance: 0.001, velocity: 0.001),
        ),
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _select(int index) {
    widget.onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extent = math.max(
      56.0,
      MediaQuery.textScalerOf(context).scale(16) * 1.5 + 24,
    );
    final restColor = colors.primaryContainer;
    final items = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < widget.destinations.length; index++)
          SizedBox(
            height: extent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Semantics(
                selected: index == widget.selectedIndex,
                child: Tooltip(
                  message: widget.destinations[index].label,
                  child: TextButton(
                    key: widget.destinationKey(index),
                    onPressed: () => _select(index),
                    style: TextButton.styleFrom(
                      foregroundColor: index == widget.selectedIndex
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.showLabels ? 16 : 0,
                      ),
                      alignment: widget.showLabels
                          ? AlignmentDirectional.centerStart
                          : Alignment.center,
                      minimumSize: Size(double.infinity, extent - 8),
                    ),
                    child: widget.showLabels
                        ? Row(
                            children: [
                              Icon(widget.destinations[index].icon),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.destinations[index].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            widget.destinations[index].icon,
                            semanticLabel: widget.destinations[index].label,
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _select((widget.selectedIndex + 1) % widget.destinations.length),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _select(
          (widget.selectedIndex - 1 + widget.destinations.length) %
              widget.destinations.length,
        ),
        const SingleActivator(LogicalKeyboardKey.home): () => _select(0),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _select(widget.destinations.length - 1),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth - 24;
          final height = extent - 8;
          return SizedBox(
            height: extent * widget.destinations.length,
            child: AnimatedBuilder(
              animation: _position,
              child: items,
              builder: (context, child) {
                final center = Offset(
                  constraints.maxWidth / 2,
                  (_position.value.clamp(0, widget.destinations.length - 1) +
                          0.5) *
                      extent,
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _reduceMotion
                            ? Stack(
                                children: [
                                  Positioned(
                                    key: const ValueKey('navigation-bubble'),
                                    left: 12,
                                    top: center.dy - height / 2,
                                    width: width,
                                    height: height,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: restColor,
                                        borderRadius: BorderRadius.circular(
                                          height / 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : LiquidGlassMotionPill(
                                key: const ValueKey('navigation-bubble'),
                                center: center,
                                active: _position.isAnimating,
                                restSize: Size(width, height),
                                activeSize: Size(
                                  width,
                                  height + _pill.growHeight,
                                ),
                                motion: _pill.motion,
                                style: _pill.effectiveGlass.copyWith(
                                  color: colors.primaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                  liteGlass:
                                      !ui.ImageFilter.isShaderFilterSupported,
                                ),
                                cover: ColoredBox(color: restColor),
                              ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
