import 'package:flutter/material.dart';

import '../models/gcode_command.dart';
import '../parser/gcode_parse_result.dart';

class CommandTimeline extends StatefulWidget {
  const CommandTimeline({
    super.key,
    required this.commands,
    required this.errors,
    this.currentIndex = -1,
    this.onTap,
    this.maxHeight,
  });

  final List<GcodeCommand> commands;
  final List<GcodeParseError> errors;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final double? maxHeight;

  @override
  State<CommandTimeline> createState() => _CommandTimelineState();
}

class _CommandTimelineState extends State<CommandTimeline> {
  late List<_TimelineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildTimelineItems();
  }

  @override
  void didUpdateWidget(covariant CommandTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.commands, oldWidget.commands) ||
        !identical(widget.errors, oldWidget.errors)) {
      _items = _buildTimelineItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.maxHeight != null
          ? BoxConstraints(maxHeight: widget.maxHeight!)
          : null,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Text(
                  '指令列表 (${widget.commands.length})',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.errors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.errors.length} 错误',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final cmd = item.command;
                final error = item.error;
                final commandIndex = item.commandIndex;
                final isCurrent =
                    commandIndex >= 0 && commandIndex == widget.currentIndex;
                final hasError = error != null;
                final code = cmd?.code;

                return InkWell(
                  onTap: widget.onTap != null && commandIndex >= 0
                      ? () => widget.onTap!(commandIndex)
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primaryContainer
                          : hasError
                              ? Colors.red.withValues(alpha: 0.05)
                              : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${item.lineNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasError
                                  ? Colors.red.shade500
                                  : Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: hasError
                                ? Colors.red.withValues(alpha: 0.15)
                                : code == 'G0'
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            hasError ? 'ERR' : code ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasError
                                  ? Colors.red
                                  : code == 'G0'
                                      ? Colors.blue
                                      : Colors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.rawLine,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: hasError
                                      ? Colors.red.shade700
                                      : isCurrent
                                          ? null
                                          : Colors.grey.shade700,
                                ),
                              ),
                              if (hasError)
                                Text(
                                  error.message,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineItem> _buildTimelineItems() {
    final items = <_TimelineItem>[
      for (final (index, command) in widget.commands.indexed)
        _TimelineItem.command(command, index),
      for (final error in widget.errors) _TimelineItem.error(error),
    ];
    items.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    return items;
  }
}

class _TimelineItem {
  const _TimelineItem._({
    required this.lineNumber,
    required this.rawLine,
    this.command,
    this.error,
    this.commandIndex = -1,
  });

  factory _TimelineItem.command(GcodeCommand command, int commandIndex) =>
      _TimelineItem._(
        lineNumber: command.lineNumber,
        rawLine: command.rawLine,
        command: command,
        commandIndex: commandIndex,
      );

  factory _TimelineItem.error(GcodeParseError error) => _TimelineItem._(
        lineNumber: error.lineNumber,
        rawLine: error.rawLine,
        error: error,
      );

  final int lineNumber;
  final String rawLine;
  final GcodeCommand? command;
  final GcodeParseError? error;
  final int commandIndex;
}
