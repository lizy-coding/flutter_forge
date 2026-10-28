import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Material Slider's OverlayPortal can emit orphan semantics during route or
// surface insertion on Flutter 3.47.2 (flutter/flutter#190357). Keep this local
// to the affected Windows controls until the upstream fix is verified.
class LearningSlider extends StatefulWidget {
  const LearningSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticFormatterCallback,
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String Function(double)? semanticFormatterCallback;

  @override
  State<LearningSlider> createState() => _LearningSliderState();
}

class _LearningSliderState extends State<LearningSlider> {
  final _focus = FocusNode();
  bool get _enabled => widget.onChanged != null && widget.max > widget.min;
  double get _step => (widget.max - widget.min) / (widget.divisions ?? 100);

  String _format(double value) =>
      widget.semanticFormatterCallback?.call(value) ??
      '${((value - widget.min) / (widget.max - widget.min) * 100).round()}%';

  double _clamp(double value) => value.clamp(widget.min, widget.max);

  void _adjust(double value) {
    if (!_enabled) return;
    final next = _clamp(value);
    if (next == widget.value) return;
    widget.onChangeStart?.call(widget.value);
    widget.onChanged!(next);
    widget.onChangeEnd?.call(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final value = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => widget.value + (rtl ? -_step : _step),
      LogicalKeyboardKey.arrowLeft => widget.value + (rtl ? _step : -_step),
      LogicalKeyboardKey.arrowUp => widget.value + _step,
      LogicalKeyboardKey.arrowDown => widget.value - _step,
      LogicalKeyboardKey.home => widget.min,
      LogicalKeyboardKey.end => widget.max,
      _ => null,
    };
    if (value == null) return KeyEventResult.ignored;
    _adjust(value);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      return Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.label,
        onChanged: widget.onChanged,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
        semanticFormatterCallback: widget.semanticFormatterCallback,
      );
    }
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      slider: true,
      enabled: _enabled,
      focusable: _enabled,
      focused: _focus.hasFocus,
      value: widget.max > widget.min ? _format(widget.value) : widget.label,
      increasedValue: _enabled && widget.value < widget.max
          ? _format(_clamp(widget.value + _step))
          : null,
      decreasedValue: _enabled && widget.value > widget.min
          ? _format(_clamp(widget.value - _step))
          : null,
      onIncrease: _enabled && widget.value < widget.max
          ? () => _adjust(widget.value + _step)
          : null,
      onDecrease: _enabled && widget.value > widget.min
          ? () => _adjust(widget.value - _step)
          : null,
      child: Focus(
        focusNode: _focus,
        canRequestFocus: _enabled,
        onKeyEvent: _onKey,
        onFocusChange: (_) => setState(() {}),
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focus.hasFocus ? colors.primary : Colors.transparent,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: !_enabled
                    ? null
                    : (details) {
                        _focus.requestFocus();
                        var fraction =
                            (details.localPosition.dx / constraints.maxWidth)
                                .clamp(0.0, 1.0);
                        if (Directionality.of(context) == TextDirection.rtl) {
                          fraction = 1 - fraction;
                        }
                        if (widget.divisions != null) {
                          fraction =
                              (fraction * widget.divisions!).round() /
                              widget.divisions!;
                        }
                        _adjust(
                          widget.min + fraction * (widget.max - widget.min),
                        );
                      },
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: CupertinoSlider(
                    // Cupertino normalizes by max - min internally. Represent
                    // a fixed range as a disabled unit track to avoid 0 / 0.
                    value: widget.max == widget.min ? 0 : widget.value,
                    min: widget.max == widget.min ? 0 : widget.min,
                    max: widget.max == widget.min ? 1 : widget.max,
                    divisions: widget.divisions,
                    activeColor: colors.primary,
                    thumbColor: _enabled ? colors.primary : colors.outline,
                    onChanged: _enabled ? widget.onChanged : null,
                    onChangeStart: (value) {
                      _focus.requestFocus();
                      widget.onChangeStart?.call(value);
                    },
                    onChangeEnd: widget.onChangeEnd,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
