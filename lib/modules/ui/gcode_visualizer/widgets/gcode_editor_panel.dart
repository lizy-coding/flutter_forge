import 'package:flutter/material.dart';

class GcodeEditorPanel extends StatefulWidget {
  const GcodeEditorPanel({
    super.key,
    required this.initialText,
    required this.onParse,
    required this.onResetSample,
    required this.errorCount,
    required this.commandCount,
    required this.hasParsed,
    required this.linesRead,
    required this.loadStageLabel,
  });

  final String initialText;
  final VoidCallback onParse;
  final VoidCallback onResetSample;
  final int errorCount;
  final int commandCount;
  final bool hasParsed;
  final int linesRead;
  final String loadStageLabel;

  @override
  State<GcodeEditorPanel> createState() => GcodeEditorPanelState();
}

class GcodeEditorPanelState extends State<GcodeEditorPanel> {
  late final TextEditingController _controller;
  bool _resetPressed = false;
  bool _parsePressed = false;
  bool _resetHovered = false;
  bool _parseHovered = false;

  String get text => _controller.text;
  set text(String value) => _controller.text = value;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 2, 8),
            child: Row(
              children: [
                Text(
                  'G-code 编辑器',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildGestureButton(
                  hovered: _resetHovered,
                  pressed: _resetPressed,
                  onHoverChanged: (v) => setState(() => _resetHovered = v),
                  onPressedChanged: (v) => setState(() => _resetPressed = v),
                  onTap: widget.onResetSample,
                  borderRadius: 6,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('示例',
                          style: TextStyle(
                              fontSize: 12, color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _buildGestureButton(
                  hovered: _parseHovered,
                  pressed: _parsePressed,
                  onHoverChanged: (v) => setState(() => _parseHovered = v),
                  onPressedChanged: (v) => setState(() => _parsePressed = v),
                  onTap: widget.onParse,
                  borderRadius: 6,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  background: theme.colorScheme.primary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 16, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 4),
                      Text('解析',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (widget.hasParsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.loadStageLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.linesRead > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.linesRead} 行',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.commandCount} 指令',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.errorCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.errorCount} 错误',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGestureButton({
    required bool hovered,
    required bool pressed,
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<bool> onPressedChanged,
    required VoidCallback onTap,
    required double borderRadius,
    required EdgeInsetsGeometry padding,
    Color? background,
    required Widget child,
  }) {
    final isFilled = background != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: background ?? Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: InkWell(
            onTap: onTap,
            onHover: onHoverChanged,
            onTapDown: (_) => onPressedChanged(true),
            onTapUp: (_) => onPressedChanged(false),
            onTapCancel: () => onPressedChanged(false),
            borderRadius: BorderRadius.circular(borderRadius),
            hoverColor: isFilled
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.blue.withValues(alpha: 0.08),
            splashColor: isFilled
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.blue.withValues(alpha: 0.16),
            child: AnimatedScale(
              scale: pressed
                  ? 0.92
                  : hovered
                      ? 1.06
                      : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
