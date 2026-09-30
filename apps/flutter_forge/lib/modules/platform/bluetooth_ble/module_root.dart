import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../../shared/learning/learning_scaffold.dart';
import 'state/ble_session.dart';

class BluetoothBlePage extends StatefulWidget {
  const BluetoothBlePage({super.key, this.client});

  final BleClient? client;

  @override
  State<BluetoothBlePage> createState() => _BluetoothBlePageState();
}

class _BluetoothBlePageState extends State<BluetoothBlePage>
    with WidgetsBindingObserver {
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
      if (device.deviceId == session.connectedId) return false;
      if (session.systemDevices.containsKey(device.deviceId) ||
          session.systemAudioDevices.any(
            (audio) => audio.id == device.deviceId,
          )) {
        return false;
      }
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
    WidgetsBinding.instance.addObserver(this);
    session = BleSession(widget.client ?? UniversalBleClient());
    session.addListener(_changed);
    session.refreshStatus();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) session.refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          _section('当前连接', [
            OutlinedButton.icon(
              key: const Key('ble-system-devices'),
              onPressed: session.refreshingConnections
                  ? null
                  : session.loadSystemDevices,
              icon: const Icon(Icons.refresh),
              label: Text(session.refreshingConnections ? '正在刷新连接…' : '刷新系统连接'),
            ),
            if (!session.permissionGranted)
              const Text('点击刷新系统连接授予权限后，可显示系统已连接设备。'),
            if (session.connectedId == null &&
                session.systemDevices.isEmpty &&
                session.systemAudioDevices.isEmpty &&
                session.permissionGranted)
              const Text('当前没有已连接设备。可开始扫描，或在系统蓝牙设置中连接设备。'),
            if (session.connectionQueryError != null)
              Text(
                session.connectionQueryError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (session.connectedId != null) ...[
              Text(
                _deviceName(
                  session.devices[session.connectedId] ??
                      BleDevice(deviceId: session.connectedId!, name: null),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SelectableText('设备标识：${session.connectedId}'),
              Text('应用 BLE 已连接 · GATT 服务：${session.services.length} 项'),
              OutlinedButton.icon(
                key: const Key('ble-disconnect'),
                onPressed: session.disconnect,
                icon: const Icon(Icons.link_off),
                label: const Text('断开连接'),
              ),
            ],
            ..._systemConnections(),
            if (defaultTargetPlatform == TargetPlatform.android) ...[
              const Text('此列表查询 BLE、音频与通话连接；手表等 HID 连接可能无法列出，请在系统设置中查看。'),
              TextButton(
                onPressed: session.openBluetoothSettings,
                child: const Text('查看完整系统连接列表'),
              ),
            ],
          ]),
          _section('蓝牙与权限', [
            Text('适配器：${_availabilityLabel(session.availabilityState)}'),
            Text('权限：${session.permissionGranted ? '已授予' : '未授予或待确认'}'),
            Wrap(
              spacing: 8,
              children: [
                if (defaultTargetPlatform == TargetPlatform.android &&
                    session.availabilityState == AvailabilityState.poweredOff)
                  FilledButton.icon(
                    key: const Key('ble-enable-bluetooth'),
                    onPressed: session.busy
                        ? null
                        : session.requestEnableBluetooth,
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('请求开启系统蓝牙'),
                  ),
                OutlinedButton(
                  onPressed: session.busy ? null : session.refreshStatus,
                  child: const Text('刷新状态'),
                ),
                if (defaultTargetPlatform == TargetPlatform.android)
                  OutlinedButton.icon(
                    key: const Key('ble-bluetooth-settings'),
                    onPressed: session.openBluetoothSettings,
                    icon: const Icon(Icons.settings_bluetooth),
                    label: Text(
                      session.availabilityState == AvailabilityState.poweredOn
                          ? '关闭蓝牙（系统设置）'
                          : '系统蓝牙设置',
                    ),
                  ),
              ],
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              const Text('开启需系统确认；关闭请在系统设置中操作，将影响所有蓝牙连接。'),
            if (defaultTargetPlatform == TargetPlatform.macOS &&
                session.availabilityState == AvailabilityState.poweredOff)
              const Text('请在 macOS 系统设置中开启蓝牙，然后刷新状态。'),
          ]),
          _section('附近设备', [
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
              ],
            ),
            Text(
              defaultTargetPlatform == TargetPlatform.android
                  ? '附近广播不代表已经连接。系统音频与 BLE 连接显示在页面顶部。'
                  : '附近广播不代表已经连接。系统 BLE 连接显示在页面顶部。',
            ),
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
          _section('服务与特征值', [
            if (session.connectedId == null) const Text('连接外设后显示 GATT 服务。'),
            if (session.connectedId != null) ...[
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
          const LearningObjectives(
            objectives: [
              '操作 BLE 扫描、连接、服务发现、读取与订阅、断开',
              '只对特征值声明支持的操作开放按钮；数值按原始十六进制展示',
              '对比平台权限、设备断开和资源释放行为',
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _systemConnections() {
    final audioById = {
      for (final device in session.systemAudioDevices) device.id: device,
    };
    final ids = {...session.systemDevices.keys, ...audioById.keys}
      ..remove(session.connectedId);
    return [
      for (final id in ids)
        ListTile(
          key: ValueKey('system-connection-$id'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            audioById.containsKey(id)
                ? Icons.headphones
                : Icons.bluetooth_connected,
          ),
          title: Text(
            audioById[id]?.name ??
                _deviceName(
                  session.systemDevices[id] ??
                      BleDevice(deviceId: id, name: null),
                ),
          ),
          subtitle: Text(
            [
              if (audioById[id] case final audio?)
                '系统已连接 · ${audio.profiles.join('、')}',
              if (session.systemDevices.containsKey(id)) '系统 BLE 已连接',
              id,
            ].join('\n'),
          ),
          trailing: session.systemDevices.containsKey(id)
              ? TextButton(
                  onPressed: session.busy || session.connectedId != null
                      ? null
                      : () => session.connect(session.systemDevices[id]!),
                  child: const Text('连接 GATT'),
                )
              : null,
        ),
    ];
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
