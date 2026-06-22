import 'package:flutter/material.dart';
import 'package:gcode_core/gcode_core.dart';

class CurrentSegmentInspector extends StatelessWidget {
  const CurrentSegmentInspector({
    super.key,
    required this.segment,
    required this.progress,
  });

  final ToolpathSegment? segment;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '当前轨迹段',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (segment == null)
            Text(
              '无轨迹段',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          else
            ..._buildSegmentInfo(segment!),
        ],
      ),
    );
  }

  List<Widget> _buildSegmentInfo(ToolpathSegment seg) {
    return [
      _infoRow('行号', '#${seg.command.lineNumber}'),
      _infoRow('指令', seg.command.rawLine),
      _infoRow(
          '类型', seg.type == GcodeSegmentType.rapid ? 'G0 快速移动' : 'G1 线性移动'),
      _infoRow('起点', 'X ${_fmt(seg.start.x)}  Y ${_fmt(seg.start.y)}'),
      _infoRow('终点', 'X ${_fmt(seg.end.x)}  Y ${_fmt(seg.end.y)}'),
      _infoRow(
          '进给率',
          seg.command.feedRate != null
              ? 'F ${_fmt(seg.command.feedRate!)}'
              : '--'),
      _infoRow('段进度', '${(progress * 100).toStringAsFixed(0)}%'),
    ];
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
