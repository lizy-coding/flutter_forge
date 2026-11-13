import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:usb_detector_bridge/usb_detector_bridge.dart';

import 'usb_detector_session.dart';

class UsbDetectorPage extends StatefulWidget {
  const UsbDetectorPage({super.key, required this.title});

  final String title;

  @override
  State<UsbDetectorPage> createState() => _UsbDetectorPageState();
}

class _UsbDetectorPageState extends State<UsbDetectorPage> {
  final UsbDetectorSession _session = UsbDetectorSession();
  List<UsbDeviceInfo> _devices = [];
  bool _capabilityResolved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChange);
    _session.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _session.addListener(_onSessionChange);
    await _session.initialize();
    unawaited(_session.loadSystemInfo());
    if (mounted) {
      setState(() {
        _capabilityResolved = _session.capabilityResolved;
      });
      _onSessionChange();
    }
  }

  void _onSessionChange() {
    if (!mounted) return;
    setState(() {
      _devices = _session.devices;
      _capabilityResolved = _session.capabilityResolved;
    });
  }

  Future<void> _refreshDevices() async {
    await _session.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcomeStatus = _session.listResult?.status;
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
                          switch (outcomeStatus) {
                            UsbDetectionStatus.available => Icons.check_circle,
                            UsbDetectionStatus.unsupported =>
                              Icons.info_outline,
                            UsbDetectionStatus.unavailable ||
                            UsbDetectionStatus.invalidData ||
                            UsbDetectionStatus.failed => Icons.error_outline,
                            null ||
                            UsbDetectionStatus.pending => Icons.hourglass_top,
                          },
                          color: switch (outcomeStatus) {
                            UsbDetectionStatus.available => Colors.green,
                            UsbDetectionStatus.unsupported => Colors.orange,
                            UsbDetectionStatus.unavailable ||
                            UsbDetectionStatus.invalidData ||
                            UsbDetectionStatus.failed => Colors.red,
                            null || UsbDetectionStatus.pending => Colors.blue,
                          },
                        ),
                        Text('USB适配器状态', style: theme.textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_session.statusText),
                    if (_session.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_session.reason!.code}：${_session.reason!.message}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (_session.systemInfo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _session.systemInfo!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'USB设备列表 (${_devices.length})',
              style: theme.textTheme.headlineSmall,
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
                            _capabilityResolved ? '未检测到USB设备' : 'USB服务未初始化',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
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
                                Text('状态: ${device.status.uiLabel}'),
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
                                device.status.uiLabel,
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
      sections: const [
        LearningObjectives(
          objectives: [
            '理解平台能力桥接包的分层：平台接口、MethodChannel 适配器与类型化结果',
            '掌握 queryCapabilities 能力探测与不支持平台的降级展示',
            '学会用 Outcome + 原因码区分"平台不支持"与"运行期失败"',
          ],
        ),
        ConceptChips(
          concepts: ['USB', '设备检测', 'MethodChannel', '平台接口', '能力查询'],
        ),
        CodeSnippetCard(
          title: '桥接包使用（usb_detector_bridge）',
          code:
              'final bridge = UsbDetectorBridge();\n'
              'final capabilities = await bridge.queryCapabilities();\n'
              'if (capabilities.isSupported) {\n'
              '  final outcome = await bridge.listDevices();\n'
              '  if (outcome.isAvailable) {\n'
              '    // outcome.value 是 List<UsbDeviceInfo>\n'
              '  }\n'
              '  // 否则按 outcome.status 展示原因码\n'
              '}',
          explanation: '模块只消费平台接口与结果类型；原生实现自注册通道，宿主 App 不再手动接线。',
        ),
        CommonPitfalls(
          pitfalls: [
            'USB 检测需要平台特定权限 — macOS 需在 entitlements 中声明，Android 序列号等描述符需用户授权后才可读',
            '平台通道调用可能失败或缺失 — 用类型化 Outcome 与原因码承接，不要把异常转成界面字符串',
            '设备热插拔监听需及时注册 — initState 中启动轮询，dispose 中释放',
          ],
        ),
        ExerciseCard(
          task: '把轮询扫描改为对比前后两次设备列表，设备数量变化时弹出 SnackBar 提示插入或拔出。',
          hint:
              '在 session.refresh() 后保存上一次 devices 长度，比较差异后使用 ScaffoldMessenger.of(context).showSnackBar()。',
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

extension _UsbDeviceStatusUiLabel on UsbDeviceStatus {
  String get uiLabel => switch (this) {
    UsbDeviceStatus.connected => '已连接',
    UsbDeviceStatus.disconnected => '已断开',
    UsbDeviceStatus.error => '错误',
    UsbDeviceStatus.unknown => '未知',
  };
}
