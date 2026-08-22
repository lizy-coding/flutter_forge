/// 消息类型枚举
enum MessageType {
  /// 普通信息
  info,

  /// 警告信息
  warning,

  /// 错误信息
  error,

  /// 成功信息
  success,

  /// 系统信息
  system,
}

/// 消息模型类，用于在Stream中传递的数据结构
class MessageModel {
  /// 消息ID
  final String id;

  /// 消息内容
  final String content;

  /// 消息类型
  final MessageType type;

  /// 消息时间戳
  final DateTime timestamp;

  /// 构造函数
  MessageModel({
    required this.id,
    required this.content,
    this.type = MessageType.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 从JSON构造
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.info,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 创建错误消息
  factory MessageModel.error(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.error,
    );
  }

  /// 创建系统消息
  factory MessageModel.system(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.system,
    );
  }

  /// 创建成功消息
  factory MessageModel.success(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.success,
    );
  }

  /// 创建警告消息
  factory MessageModel.warning(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.warning,
    );
  }

  /// 格式化时间戳
  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  @override
  String toString() =>
      '[$formattedTime] ${type.toString().split('.').last.toUpperCase()}: $content';
}
