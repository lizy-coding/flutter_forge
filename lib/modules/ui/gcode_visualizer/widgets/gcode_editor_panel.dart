import 'package:flutter/material.dart';

class GcodeEditorPanel extends StatefulWidget {
  const GcodeEditorPanel({
    super.key,
    required this.initialText,
    required this.onParse,
    required this.onLoadFilePath,
    required this.onPickFilePath,
    required this.onResetSample,
    required this.errorCount,
    required this.commandCount,
    required this.segmentCount,
    required this.hasParsed,
    required this.linesRead,
    required this.loadStageLabel,
    required this.loadMessage,
  });

  final String initialText;
  final VoidCallback onParse;
  final ValueChanged<String> onLoadFilePath;
  final Future<String?> Function() onPickFilePath;
  final VoidCallback onResetSample;
  final int errorCount;
  final int commandCount;
  final int segmentCount;
  final bool hasParsed;
  final int linesRead;
  final String loadStageLabel;
  final String loadMessage;

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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: OverflowBar(
              spacing: 4,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                Text(
                  'G-code 编辑器',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          _GcodeFilePathInput(
            onLoadFilePath: widget.onLoadFilePath,
            onPickFilePath: widget.onPickFilePath,
          ),
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
          if (widget.hasParsed || widget.loadMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _badge(widget.loadStageLabel, Colors.grey.shade700,
                      Colors.grey.withValues(alpha: 0.12)),
                  if (widget.linesRead > 0)
                    _badge('${widget.linesRead} 行', Colors.teal,
                        Colors.teal.withValues(alpha: 0.1)),
                  _badge('${widget.commandCount} 指令', Colors.blue,
                      Colors.blue.withValues(alpha: 0.1)),
                  if (widget.segmentCount > 0)
                    _badge('${widget.segmentCount} 轨迹段', Colors.teal,
                        Colors.teal.withValues(alpha: 0.1)),
                  if (widget.errorCount > 0)
                    _badge('${widget.errorCount} 错误', Colors.red,
                        Colors.red.withValues(alpha: 0.1)),
                ],
              ),
            ),
          if (widget.loadMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                widget.loadMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.loadStageLabel == '读取失败'
                      ? Colors.red.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
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

class _GcodeFilePathInput extends StatefulWidget {
  const _GcodeFilePathInput({
    required this.onLoadFilePath,
    required this.onPickFilePath,
  });

  final ValueChanged<String> onLoadFilePath;
  final Future<String?> Function() onPickFilePath;

  @override
  State<_GcodeFilePathInput> createState() => _GcodeFilePathInputState();
}

class _GcodeFilePathInputState extends State<_GcodeFilePathInput> {
  late final TextEditingController _controller;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '输入 G-code 文件路径',
                prefixIcon: const Icon(Icons.folder_open, size: 16),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
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
              onSubmitted: _loadPath,
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            onPressed: _isPicking ? null : _pickPath,
            icon: _isPicking
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open, size: 18),
            tooltip: '选择 G-code 文件',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.tonalIcon(
            onPressed: () => _loadPath(_controller.text),
            icon: const Icon(Icons.file_upload_outlined, size: 16),
            label: const Text('提取'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _loadPath(String value) {
    final path = value.trim();
    if (path.isEmpty) return;
    widget.onLoadFilePath(path);
  }

  Future<void> _pickPath() async {
    setState(() => _isPicking = true);
    try {
      final path = await widget.onPickFilePath();
      if (!mounted) return;
      if (path != null && path.isNotEmpty) {
        _controller.text = path;
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }
}
