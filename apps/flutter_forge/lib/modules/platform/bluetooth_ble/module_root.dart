import 'package:flutter/foundation.dart';
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

class _BluetoothBlePageState extends State<BluetoothBlePage>
    with WidgetsBindingObserver {
  late final BleSession session;
  String query = '';
  bool showUnnamed = false;
  String? selectedId;
  final _deviceScrollController = ScrollController();
  final _detailsScrollController = ScrollController();
  bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

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
      if (device.deviceId == session.connectedId ||
          session.systemDevices.containsKey(device.deviceId) ||
          session.systemAudioDevices.any(
            (audio) => audio.id == device.deviceId,
          )) {
        return false;
      }
      if (!showUnnamed && !_hasName(device)) return false;
      return search.isEmpty ||
          _deviceName(device).toLowerCase().contains(search) ||
          device.deviceId.toLowerCase().contains(search);
    }).toList();
    result.sort((a, b) {
      final named = (_hasName(b) ? 1 : 0) - (_hasName(a) ? 1 : 0);
      return named != 0 ? named : (b.rssi ?? -999).compareTo(a.rssi ?? -999);
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
    _deviceScrollController.dispose();
    _detailsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BLE 连接生命周期')),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the allocated window space, including reduced-height windows.
          final wide =
              constraints.maxWidth >= 960 &&
              constraints.maxHeight >= 560 &&
              MediaQuery.textScalerOf(context).scale(14) <= 24;
          return Padding(
            padding: EdgeInsets.all(wide ? 20 : 12),
            child: wide ? _desktopWorkspace() : _compactWorkspace(),
          );
        },
      ),
    ),
  );

  Widget _desktopWorkspace() => Column(
    key: const Key('ble-wide-layout'),
    children: [
      _statusPanel(),
      const SizedBox(height: 12),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 360,
              child: _devicePane(const Key('ble-device-pane')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ListView(
                key: const Key('ble-details-pane'),
                controller: _detailsScrollController,
                children: [
                  _applicationConnection(),
                  _gattPanel(),
                  _supportPanels(),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _compactWorkspace() =>
      _devicePane(const Key('ble-compact-layout'), compact: true);

  Widget _devicePane(Key key, {bool compact = false}) {
    final devices = _visibleDevices;
    return CustomScrollView(
      key: key,
      controller: _deviceScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) _statusPanel(),
              if (compact &&
                  (session.connectedId != null ||
                      (session.systemDevices.isEmpty &&
                          session.systemAudioDevices.isEmpty)))
                _applicationConnection(),
              _systemConnections(compact: compact),
              _scanPanel(devices.length),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) =>
              _deviceCard(devices[index], compact: compact),
        ),
        if (compact)
          SliverToBoxAdapter(
            child: Column(children: [_gattPanel(), _supportPanels()]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _statusPanel() => _panel(
    title: _isMac
        ? 'macOS 蓝牙'
        : _isWindows
        ? 'Windows 蓝牙'
        : '蓝牙与权限',
    icon: Icons.bluetooth,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _badge('适配器：${_availabilityLabel(session.availabilityState)}'),
            _badge('权限：${session.permissionGranted ? '已授予' : '待授权'}'),
            if (_isAndroid &&
                session.availabilityState == AvailabilityState.poweredOff)
              FilledButton.icon(
                key: const Key('ble-enable-bluetooth'),
                onPressed: session.busy ? null : session.requestEnableBluetooth,
                icon: const Icon(Icons.bluetooth),
                label: const Text('请求开启系统蓝牙'),
              ),
            if (_isAndroid || _isMac || _isWindows)
              OutlinedButton.icon(
                key: Key(
                  _isAndroid
                      ? 'ble-bluetooth-settings'
                      : _isMac
                      ? 'ble-macos-settings'
                      : 'ble-windows-settings',
                ),
                onPressed: session.openBluetoothSettings,
                icon: const Icon(Icons.settings_bluetooth),
                label: Text(
                  _isAndroid &&
                          session.availabilityState ==
                              AvailabilityState.poweredOn
                      ? '关闭蓝牙（系统设置）'
                      : '系统蓝牙设置',
                ),
              ),
            TextButton.icon(
              onPressed: session.busy ? null : session.refreshStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新状态'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _isMac
              ? '在系统设置中管理蓝牙开关；此处查看 BLE 状态与 GATT 连接。'
              : _isWindows
              ? '连接支持 GATT 的 BLE 外设；在系统设置中管理蓝牙开关。'
              : '开启需系统确认；关闭将在系统设置中操作，影响所有蓝牙连接。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (session.error != null) ...[
          const SizedBox(height: 8),
          Text(
            session.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );

  Widget _applicationConnection() => _panel(
    title: '当前连接',
    icon: Icons.link,
    child: session.connectedId == null
        ? const Text('本应用尚未建立 GATT 连接。选择附近设备或系统 BLE 设备后连接。')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _deviceName(
                  session.devices[session.connectedId] ??
                      BleDevice(deviceId: session.connectedId!, name: null),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SelectableText('设备标识：${session.connectedId}'),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('应用 BLE 已连接 · GATT 服务：${session.services.length} 项'),
                  OutlinedButton.icon(
                    key: const Key('ble-disconnect'),
                    onPressed: session.disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('断开连接'),
                  ),
                ],
              ),
            ],
          ),
  );

  Widget _systemConnections({bool compact = false}) {
    final audio = {
      for (final device in session.systemAudioDevices) device.id: device,
    };
    final ids = {...session.systemDevices.keys, ...audio.keys}
      ..remove(session.connectedId);
    return _panel(
      title: compact && session.connectedId == null && ids.isNotEmpty
          ? '当前连接'
          : _isAndroid
          ? '系统连接'
          : '系统 BLE 设备',
      icon: Icons.bluetooth_connected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: const Key('ble-system-devices'),
            onPressed: session.refreshingConnections
                ? null
                : session.loadSystemDevices,
            icon: const Icon(Icons.refresh),
            label: Text(session.refreshingConnections ? '正在刷新连接…' : '刷新系统连接'),
          ),
          if (!session.permissionGranted)
            const Text('刷新系统连接并授予权限后查询设备。')
          else if (ids.isEmpty && !session.refreshingConnections)
            Text(
              _isMac
                  ? session.connectedId != null
                        ? '未查询到其他匹配服务的系统 BLE 设备。'
                        : '未查询到匹配服务的系统 BLE 设备。查询结果不包含完整系统蓝牙连接。'
                  : '未查询到系统 BLE 连接；本应用连接单独显示。',
            ),
          for (final id in ids)
            Padding(
              key: ValueKey('system-connection-$id'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio[id]?.name ??
                        _deviceName(
                          session.systemDevices[id] ??
                              BleDevice(deviceId: id, name: null),
                        ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    [
                      if (audio[id] case final device?)
                        '系统已连接 · ${device.profiles.join('、')}',
                      if (session.systemDevices.containsKey(id)) '系统 BLE 已连接',
                    ].join(' · '),
                  ),
                  if (session.systemDevices.containsKey(id))
                    TextButton(
                      onPressed: session.busy || session.connectedId != null
                          ? null
                          : () => _connect(session.systemDevices[id]!),
                      child: const Text('连接 GATT'),
                    ),
                ],
              ),
            ),
          if (session.connectionQueryError != null)
            Text(
              session.connectionQueryError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_isAndroid) const Text('覆盖 BLE、音频与通话；HID 等连接请在系统设置中查看。'),
          if (_isMac) const Text('按标准服务筛选已连接外设，自定义服务设备可能无法列出。'),
        ],
      ),
    );
  }

  Widget _scanPanel(int visibleCount) => _panel(
    title: '附近设备',
    icon: Icons.radar,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('ble-scan'),
              onPressed:
                  session.busy ||
                      session.scanning ||
                      session.connectedId != null
                  ? null
                  : session.startScan,
              icon: const Icon(Icons.search),
              label: Text(session.scanning ? '扫描中…' : '开始扫描'),
            ),
            OutlinedButton(
              onPressed: session.scanning ? session.stopScan : null,
              child: const Text('停止扫描'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        Text('已发现 ${session.devices.length} 台 · 当前显示 $visibleCount 台'),
        FilterChip(
          label: Text(
            '显示未命名 (${session.devices.values.where((d) => !_hasName(d)).length})',
          ),
          selected: showUnnamed,
          onSelected: (value) => setState(() => showUnnamed = value),
        ),
        if (visibleCount == 0)
          Text(
            session.scanning
                ? '等待外设广播…'
                : session.devices.isEmpty
                ? '开始扫描以发现附近 BLE 外设。'
                : '没有匹配的附近设备。可修改搜索词或显示未命名设备。',
          ),
      ],
    ),
  );

  void _connect(BleDevice device) {
    setState(() => selectedId = device.deviceId);
    session.connect(device);
  }

  Widget _deviceCard(BleDevice device, {required bool compact}) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          selected: selectedId == device.deviceId,
          leading: const Icon(Icons.bluetooth),
          title: Text(
            _deviceName(device),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            device.rssi == null ? '附近 BLE 广播' : '信号 ${device.rssi} dBm',
          ),
          onTap: () => setState(() => selectedId = device.deviceId),
          trailing: TextButton(
            onPressed: session.busy || session.connectedId != null
                ? null
                : () => _connect(device),
            child: const Text('连接'),
          ),
        ),
        if (compact)
          ExpansionTile(
            title: const Text('设备详情'),
            childrenPadding: const EdgeInsets.all(12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [_deviceDetails(device)],
          ),
      ],
    ),
  );

  Widget _deviceDetails(BleDevice device) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText('标识：${device.deviceId}'),
      const SizedBox(height: 8),
      Text(
        '广播服务：${device.services.isEmpty ? '未提供' : device.services.join(', ')}',
      ),
    ],
  );

  Widget _gattPanel() {
    final selected =
        session.devices[selectedId] ?? session.systemDevices[selectedId];
    return _panel(
      title: '服务与特征值',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.connectedId == null) ...[
            if (selected != null) ...[
              Text(
                _deviceName(selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _deviceDetails(selected),
              const SizedBox(height: 12),
            ],
            const Text('连接外设后显示 GATT 服务。读取与订阅按钮按特征值属性开放。'),
          ] else if (session.services.isEmpty)
            const Text('未发现服务，或服务发现仍在进行。')
          else
            for (final service in session.services)
              ExpansionTile(
                key: ValueKey('${session.connectedId}/${service.uuid}'),
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '服务 ${service.uuid}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text('${service.characteristics.length} 个特征值'),
                children: [
                  for (final characteristic in service.characteristics)
                    _characteristic(service, characteristic),
                ],
              ),
        ],
      ),
    );
  }

  Widget _characteristic(BleService service, BleCharacteristic characteristic) {
    final key = '${service.uuid}/${characteristic.uuid}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText('特征值 ${characteristic.uuid}'),
          Text('属性：${characteristic.properties.map((p) => p.name).join(', ')}'),
          if (session.values[key] case final value?)
            SelectableText('原始值：${BleSession.hex(value)}'),
          Wrap(
            spacing: 8,
            children: [
              if (characteristic.properties.contains(
                CharacteristicProperty.read,
              ))
                TextButton(
                  onPressed: () => session.read(service, characteristic),
                  child: const Text('读取'),
                ),
              if (characteristic.properties.contains(
                    CharacteristicProperty.notify,
                  ) ||
                  characteristic.properties.contains(
                    CharacteristicProperty.indicate,
                  ))
                TextButton(
                  onPressed: () =>
                      session.toggleSubscription(service, characteristic),
                  child: Text(
                    session.subscriptions.contains(key) ? '停止订阅' : '订阅',
                  ),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _supportPanels() => Column(
    children: [
      Card(
        child: ExpansionTile(
          title: const Text('事件记录'),
          subtitle: Text(
            session.logs.isEmpty ? '操作后记录状态变化' : session.logs.first,
          ),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final log in session.logs.take(12)) Text(log)],
        ),
      ),
      const Card(
        child: ExpansionTile(
          title: Text('学习目标与操作说明'),
          children: [
            LearningObjectives(
              objectives: [
                '扫描 → 连接 → 服务发现 → 读取或订阅 → 断开',
                '区分广播设备、系统连接与本应用 GATT 连接',
                '观察平台权限、设备断开与资源释放',
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _badge(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(label),
    ),
  );

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
