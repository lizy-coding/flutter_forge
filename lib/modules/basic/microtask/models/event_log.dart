import 'package:flutter/material.dart';

enum EventType {
  sync,
  microtask,
  event,
  info,
}

class EventLog {
  final String message;
  final EventType type;
  final DateTime timestamp;
  final int id;

  EventLog({
    required this.message,
    required this.type,
    required this.id,
  }) : timestamp = DateTime.now();

  Color get color {
    switch (type) {
      case EventType.sync:
        return Colors.black;
      case EventType.microtask:
        return Colors.blue;
      case EventType.event:
        return Colors.red;
      case EventType.info:
        return Colors.grey;
    }
  }

  String get typeText {
    switch (type) {
      case EventType.sync:
        return '【同步】';
      case EventType.microtask:
        return '【微任务】';
      case EventType.event:
        return '【事件任务】';
      case EventType.info:
        return '【信息】';
    }
  }

  String get formattedMessage => '$typeText$message';

  String get formattedTimestamp {
    final time = timestamp;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
  }
}
