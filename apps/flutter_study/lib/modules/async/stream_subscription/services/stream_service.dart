import 'dart:async';

import 'package:flutter/foundation.dart';

/// 提供Stream相关服务
class StreamService {
  /// 单例模式实现
  static final StreamService _instance = StreamService._internal();

  /// 工厂构造函数，返回单例实例
  factory StreamService() => _instance;

  /// 私有构造函数
  StreamService._internal();

  /// 单订阅Stream控制器
  late StreamController<String> _singleController;

  /// 广播Stream控制器
  late StreamController<String> _broadcastController;

  /// 初始化服务
  void initialize() {
    _singleController = StreamController<String>(
      onListen: () => debugPrint('单订阅Stream - 有人开始监听'),
      onPause: () => debugPrint('单订阅Stream - 订阅被暂停'),
      onResume: () => debugPrint('单订阅Stream - 订阅被恢复'),
      onCancel: () => debugPrint('单订阅Stream - 订阅被取消'),
    );

    _broadcastController = StreamController<String>.broadcast(
      onListen: () => debugPrint('广播Stream - 有人开始监听'),
      onCancel: () => debugPrint('广播Stream - 有人取消监听'),
    );
  }

  /// 获取单订阅Stream
  Stream<String> get singleStream => _singleController.stream;

  /// 获取广播Stream
  Stream<String> get broadcastStream => _broadcastController.stream;

  /// 发送数据到单订阅Stream
  void addToSingle(String data) {
    if (!_singleController.isClosed) {
      _singleController.add(data);
    }
  }

  /// 发送数据到广播Stream
  void addToBroadcast(String data) {
    if (!_broadcastController.isClosed) {
      _broadcastController.add(data);
    }
  }

  /// 发送错误到单订阅Stream
  void addErrorToSingle(Object error) {
    if (!_singleController.isClosed) {
      _singleController.addError(error);
    }
  }

  /// 发送错误到广播Stream
  void addErrorToBroadcast(Object error) {
    if (!_broadcastController.isClosed) {
      _broadcastController.addError(error);
    }
  }

  /// 关闭Stream控制器
  void dispose() {
    if (!_singleController.isClosed) {
      _singleController.close();
    }
    if (!_broadcastController.isClosed) {
      _broadcastController.close();
    }
  }

  /// 重新初始化Stream控制器
  void reinitialize() {
    dispose();
    initialize();
  }
}
