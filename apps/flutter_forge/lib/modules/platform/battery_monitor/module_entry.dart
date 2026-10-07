import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'battery_session.dart';

class BatteryMonitorEntry extends StatefulWidget {
  const BatteryMonitorEntry({super.key, this.battery});

  final FlutterBattery? battery;

  @override
  State<BatteryMonitorEntry> createState() => _BatteryMonitorEntryState();
}

class _BatteryMonitorEntryState extends State<BatteryMonitorEntry> {
  late final BatterySession session;

  @override
  void initState() {
    super.initState();
    session = BatterySession(widget.battery ?? FlutterBattery());
    session.initialize();
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => LearningScaffold(
        title: '电池状态与事件监听',
        interactiveDemo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.level == null ? '电量不可用' : '${session.level}%',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.info == null
                          ? '等待电池信息'
                          : session.level == null
                          ? '未检测到可读取的电池'
                          : session.info!.isCharging
                          ? '正在充电'
                          : '使用电池供电',
                    ),
                    if (session.info != null && session.level != null) ...[
                      Text(
                        '温度：${session.info!.temperature > 0 ? '${session.info!.temperature.toStringAsFixed(1)} °C' : '不可用'}',
                      ),
                      Text(
                        '电压：${session.info!.voltage > 0 ? '${session.info!.voltage.toStringAsFixed(2)} V' : '不可用'}',
                      ),
                    ],
                    if (session.health != null)
                      Text('健康状态：${session.health!.statusLabel}'),
                    Text('已接收事件：${session.eventCount}'),
                    if (session.loading) const LinearProgressIndicator(),
                    if (session.error != null) Text(session.error!),
                    if (session.streamError != null) Text(session.streamError!),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: session.loading ? null : session.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新电池状态'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('平台能力', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (session.capabilities == null)
              const Text('正在查询平台能力')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _features.entries)
                    Chip(
                      avatar: Icon(
                        session.capabilities!.isSupported(item.key)
                            ? Icons.check_circle_outline
                            : Icons.block,
                        size: 18,
                      ),
                      label: Text(
                        '${item.value}：${session.capabilities!.isSupported(item.key) ? '支持' : '不支持'}',
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            const Text('本模块仅观察电池；通知与 BLE 能力用于对照平台差异。'),
          ],
        ),
        sections: const [
          LearningObjectives(
            objectives: [
              '通过独立插件依赖读取真实电池信息',
              '用平台能力查询判断可用操作',
              '观察事件流并在页面退出时释放订阅',
            ],
          ),
          ConceptChips(
            concepts: ['插件依赖', 'MethodChannel', 'EventChannel', '能力查询', '资源释放'],
          ),
          CodeSnippetCard(
            title: '先查询能力，再读取状态',
            code:
                'final battery = FlutterBattery();\n'
                'final caps = await battery.getPlatformCapabilities();\n'
                'if (caps.isSupported(BatteryFeature.batteryInfo)) {\n'
                '  final info = await battery.getBatteryInfo();\n'
                '}\n'
                'final observation = await battery.observe(\n'
                '  options: BatteryObservationOptions(samples: {BatterySample.level}),\n'
                ');\n'
                'final subscription = observation.events.listen(onEvent);\n'
                '// 退出时取消订阅，并 await observation.close();',
            explanation: '能力表示平台接口可用；没有电池或读取失败时仍需呈现明确状态。会话独立选择采样类型、间隔并释放自己的需求。',
          ),
          CommonPitfalls(
            pitfalls: [
              '无电池或负数读数不能展示为 0% 电量',
              '异步读取完成时，页面可能已退出；避免更新已销毁状态',
              'macOS 的通知、BLE 与 peer sync 不可用；不要直接调用可选功能',
            ],
          ),
          ExerciseCard(
            task: '为电量变化增加一条本地历史记录，并限制最多保存 20 条。',
            hint: '使用事件 type 和 timestamp；在 dispose 时取消订阅。',
          ),
        ],
      ),
    );
  }
}

const _features = {
  BatteryFeature.batteryLevel: '电量读取',
  BatteryFeature.batteryInfo: '电池信息',
  BatteryFeature.batteryHealth: '健康信息',
  BatteryFeature.batteryLevelStream: '电量事件',
  BatteryFeature.nativeNotifications: '原生通知',
  BatteryFeature.scheduledNotifications: '延迟通知',
  BatteryFeature.blePeerSync: 'BLE 同步',
};
