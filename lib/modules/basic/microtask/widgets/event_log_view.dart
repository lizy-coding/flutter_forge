import 'package:flutter/material.dart';
import '../models/event_log.dart';

class EventLogView extends StatelessWidget {
  final List<EventLog> logs;
  final bool showTimestamp;
  final ScrollController? scrollController;

  const EventLogView({
    super.key,
    required this.logs,
    this.showTimestamp = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: logs.isEmpty
          ? const Center(
              child: Text(
                '点击上方按钮运行测试',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              controller: scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  color: log.color.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.id}. ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: log.color,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                log.formattedMessage,
                                style: TextStyle(
                                  color: log.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '时间戳: ${log.formattedTimestamp}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
