// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import 'models/usb_device_info.dart';
import 'services/usb_detection_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final UsbDetectionService _usbService = UsbDetectionService();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<UsbDeviceInfo> _devices = [];
  String _statusMessage = '正在初始化...';
  String _systemInfo = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUsb();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _usbService.dispose();
    super.dispose();
  }

  Future<void> _initializeUsb() async {
    bool initialized = await _usbService.initialize();
    String systemInfo = await _usbService.getSystemInfo();

    if (!mounted) return;

    setState(() {
      _isInitialized = initialized;
      _systemInfo = systemInfo;
    });

    _subscriptions.add(
      _usbService.deviceStream.listen((devices) {
        setState(() {
          _devices = devices;
        });
      }),
    );

    _subscriptions.add(
      _usbService.statusStream.listen((status) {
        setState(() {
          _statusMessage = status;
        });
      }),
    );
  }

  Future<void> _refreshDevices() async {
    await _usbService.refreshDevices();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.title,
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshDevices,
        tooltip: '刷新设备',
        child: const Icon(Icons.refresh),
      ),
      interactiveDemo: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          _isInitialized
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        Text(
                          'USB驱动状态',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_usbService.systemStatus),
                    const SizedBox(height: 4),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_systemInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _systemInfo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'USB设备列表 (${_devices.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.usb_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isInitialized ? '未检测到USB设备' : 'USB服务未初始化',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getDeviceIcon(device.status),
                              color: _getStatusColor(device.status),
                            ),
                            title: Text(device.displayName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('设备ID: ${device.deviceId}'),
                                if (device.manufacturer != null)
                                  Text('制造商: ${device.manufacturer}'),
                                if (device.serialNumber != null)
                                  Text('序列号: ${device.serialNumber}'),
                                Text('状态: ${device.status.displayName}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  device.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(device.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                device.status.displayName,
                                style: TextStyle(
                                  color: _getStatusColor(device.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '理解 Flutter 中 USB 设备检测的实现方式',
            '掌握 MethodChannel 与原生平台通信的模式',
            '学会使用 Stream 监听设备插拔事件',
          ],
        ),
        ConceptChips(
          concepts: ['USB', '设备检测', 'MethodChannel', 'Stream', '平台通道'],
        ),
        CodeSnippetCard(
          title: 'USB 检测服务使用',
          code:
              'final service = UsbDetectionService();\n'
              'await service.initialize();\n'
              'service.deviceStream.listen((devices) {\n'
              '  // 设备列表更新\n'
              '});\n'
              'service.statusStream.listen((status) {\n'
              '  // 状态变化通知\n'
              '});\n'
              'await service.refreshDevices();\n'
              'service.dispose();',
          explanation: 'UsbDetectionService 封装了平台通道调用和设备状态管理。',
        ),
        CommonPitfalls(
          pitfalls: [
            'USB 检测需要平台特定权限 — macOS 需在 entitlements 中声明，Android 需声明 USB 权限',
            '平台通道需在后台线程操作 — USB 通信可能阻塞，避免在主 Isolate 中执行耗时操作',
            '设备热插拔监听需及时注册 — initState 中启动监听，dispose 中释放',
          ],
        ),
        ExerciseCard(
          task: '实现设备连接时的 Toast 或 SnackBar 提示，当 USB 设备插入时自动弹出通知。',
          hint:
              '在 deviceStream 监听中检查设备数量变化，使用 ScaffoldMessenger.of(context).showSnackBar()。',
        ),
      ],
    );
  }

  IconData _getDeviceIcon(UsbDeviceStatus status) {
    switch (status) {
      case UsbDeviceStatus.connected:
        return Icons.usb;
      case UsbDeviceStatus.disconnected:
        return Icons.usb_off;
      case UsbDeviceStatus.error:
        return Icons.error;
      case UsbDeviceStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(UsbDeviceStatus status) {
    switch (status) {
      case UsbDeviceStatus.connected:
        return Colors.green;
      case UsbDeviceStatus.disconnected:
        return Colors.grey;
      case UsbDeviceStatus.error:
        return Colors.red;
      case UsbDeviceStatus.unknown:
        return Colors.orange;
    }
  }
}
