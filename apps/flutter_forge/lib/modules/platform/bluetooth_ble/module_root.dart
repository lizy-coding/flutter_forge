import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../../shared/learning/learning_scaffold.dart';
import 'state/ble_session.dart';

class BluetoothBlePage extends StatefulWidget {
  const BluetoothBlePage({super.key, this.client});

  final BleClient? client;

  @override
  State<BluetoothBlePage> createState() => _BluetoothBlePageState();
}

class _BluetoothBlePageState extends State<BluetoothBlePage> {
  late final BleSession session;
  String query = '';
  bool showUnnamed = false;

  String _deviceName(BleDevice device) {
    final raw = device.rawName?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final name = device.name?.trim();
    return name == null || name.isEmpty ? '未命名 BLE 设备' : name;
  }

  bool _hasName(BleDevice device) => _deviceName(device) != '未命名 BLE 设备';

  List<BleDevice> get _visibleDevices {
    final search = query.trim().toLowerCase();
    final result = session.devices.values.where((device) {
      if (!showUnnamed && !_hasName(device) && device.isSystemDevice != true) {
        return false;
      }
      return search.isEmpty ||
          _deviceName(device).toLowerCase().contains(search) ||
          device.deviceId.toLowerCase().contains(search);
    }).toList();
    result.sort((a, b) {
      final system =
          (b.isSystemDevice == true ? 1 : 0) -
          (a.isSystemDevice == true ? 1 : 0);
      if (system != 0) return system;
      final named = (_hasName(b) ? 1 : 0) - (_hasName(a) ? 1 : 0);
      if (named != 0) return named;
      return (b.rssi ?? -999).compareTo(a.rssi ?? -999);
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    session = BleSession(widget.client ?? UniversalBleClient());
    session.addListener(_changed);
    session.refreshStatus();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_changed);
    session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE 连接生命周期')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LearningObjectives(
            objectives: [
              '操作 BLE 扫描、连接、服务发现、读取与订阅、断开；连接与 GATT 流程待手工验证',
              '只对特征值声明支持的操作开放按钮；数值按原始十六进制展示',
              '对比平台权限、设备断开和资源释放行为',
            ],
          ),
          const SizedBox(height: 16),
          _section('1. 蓝牙状态与权限', [
            Text('适配器：${_availabilityLabel(session.availabilityState)}'),
            Text('权限：${session.permissionGranted ? '已授予' : '未授予或待确认'}'),
            TextButton(
              onPressed: session.refreshStatus,
              child: const Text('刷新状态'),
            ),
          ]),
          _section('2. 附近设备扫描', [
            Text(session.scanning ? '扫描中…' : '未扫描'),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const Key('ble-scan'),
                  onPressed:
                      session.busy ||
                          session.scanning ||
                          session.connectedId != null
                      ? null
                      : session.startScan,
                  child: const Text('开始扫描'),
                ),
                OutlinedButton(
                  onPressed: session.scanning ? session.stopScan : null,
                  child: const Text('停止扫描'),
                ),
                OutlinedButton(
                  key: const Key('ble-system-devices'),
                  onPressed:
                      session.busy ||
                          session.scanning ||
                          session.connectedId != null
                      ? null
                      : session.loadSystemDevices,
                  child: const Text('系统已连接设备'),
                ),
              ],
            ),
            const Text('系统设备查询仅返回可访问的 BLE/GATT 设备；蓝牙音频连接不一定出现在此列表。'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('ble-device-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: '搜索设备名称或标识',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '已发现 ${session.devices.length} 台 · 当前显示 ${_visibleDevices.length} 台',
                ),
                FilterChip(
                  label: Text(
                    '显示未命名 (${session.devices.values.where((d) => !_hasName(d)).length})',
                  ),
                  selected: showUnnamed,
                  onSelected: (value) => setState(() => showUnnamed = value),
                ),
              ],
            ),
            if (session.devices.isEmpty && !session.scanning)
              const Text('尚无设备。扫描结束后仍为空时，请确认外设正在广播。'),
            if (session.devices.isNotEmpty && _visibleDevices.isEmpty)
              const Text('没有匹配的设备。可更改搜索词或显示未命名设备。'),
            for (final device in _visibleDevices)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(_deviceName(device)),
                      subtitle: Text(
                        [
                          if (device.isSystemDevice == true) '系统已连接',
                          if (device.rssi != null) '信号 ${device.rssi} dBm',
                          if (device.timestampDateTime != null)
                            '最近发现 ${TimeOfDay.fromDateTime(device.timestampDateTime!).format(context)}',
                        ].join(' · '),
                      ),
                      trailing: TextButton(
                        onPressed: session.busy || session.connectedId != null
                            ? null
                            : () => session.connect(device),
                        child: const Text('连接'),
                      ),
                    ),
                    ExpansionTile(
                      title: const Text('设备详情'),
                      children: [
                        SelectableText('标识：${device.deviceId}'),
                        Text(
                          '广播服务：${device.services.isEmpty ? '未提供' : device.services.join(', ')}',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
          ]),
          _section('3. 服务与特征值', [
            if (session.connectedId == null) const Text('连接外设后显示 GATT 服务。'),
            if (session.connectedId != null) ...[
              Text('已连接：${session.connectedId}'),
              OutlinedButton(
                key: const Key('ble-disconnect'),
                onPressed: session.disconnect,
                child: const Text('断开连接'),
              ),
              if (session.services.isEmpty) const Text('未发现服务，或服务发现仍在进行。'),
              for (final service in session.services)
                ExpansionTile(
                  title: Text('服务 ${service.uuid}'),
                  children: [
                    for (final characteristic in service.characteristics)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText('特征值 ${characteristic.uuid}'),
                            Text(
                              '属性：${characteristic.properties.map((p) => p.name).join(', ')}',
                            ),
                            if (session
                                    .values['${service.uuid}/${characteristic.uuid}']
                                case final value?)
                              SelectableText('原始值：${BleSession.hex(value)}'),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (characteristic.properties.contains(
                                  CharacteristicProperty.read,
                                ))
                                  TextButton(
                                    onPressed: () =>
                                        session.read(service, characteristic),
                                    child: const Text('读取'),
                                  ),
                                if (characteristic.properties.contains(
                                      CharacteristicProperty.notify,
                                    ) ||
                                    characteristic.properties.contains(
                                      CharacteristicProperty.indicate,
                                    ))
                                  TextButton(
                                    onPressed: () => session.toggleSubscription(
                                      service,
                                      characteristic,
                                    ),
                                    child: Text(
                                      session.subscriptions.contains(
                                            '${service.uuid}/${characteristic.uuid}',
                                          )
                                          ? '停止订阅'
                                          : '订阅',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ]),
          if (session.error != null)
            Text(
              session.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          _section('事件记录', [
            for (final log in session.logs.take(12)) Text(log),
            if (session.logs.isEmpty) const Text('操作后显示状态变化与错误。'),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  String _availabilityLabel(AvailabilityState state) => switch (state) {
    AvailabilityState.poweredOn => '已开启',
    AvailabilityState.poweredOff => '已关闭',
    AvailabilityState.unauthorized => '未授权',
    AvailabilityState.unsupported => '不支持',
    AvailabilityState.resetting => '重置中',
    AvailabilityState.unknown => '未知',
  };
}
