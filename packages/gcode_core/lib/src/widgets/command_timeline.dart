import 'package:flutter/material.dart';

import '../models/gcode_command.dart';
import '../parser/gcode_parse_result.dart';

class CommandTimeline extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final items = _buildTimelineItems();

    return Container(
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
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
                  '指令列表 (${commands.length})',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (errors.isNotEmpty)
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
                        '${errors.length} 错误',
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
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final cmd = item.command;
                final error = item.error;
                final commandIndex = cmd == null ? -1 : commands.indexOf(cmd);
                final isCurrent =
                    commandIndex >= 0 && commandIndex == currentIndex;
                final hasError = error != null;
                final code = cmd?.code;

                return InkWell(
                  onTap: onTap != null && commandIndex >= 0
                      ? () => onTap!(commandIndex)
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
      for (final command in commands) _TimelineItem.command(command),
      for (final error in errors) _TimelineItem.error(error),
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
  });

  factory _TimelineItem.command(GcodeCommand command) => _TimelineItem._(
        lineNumber: command.lineNumber,
        rawLine: command.rawLine,
        command: command,
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
}
