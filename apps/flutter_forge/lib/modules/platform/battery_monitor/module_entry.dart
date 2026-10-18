import 'dart:async';

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
    unawaited(session.initialize());
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
                      session.level == null
                          ? session.statusText
                          : '${session.level}%',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.level == null
                          ? session.statusText
                          : session.powerText,
                    ),
                    if (session.info != null && session.level != null) ...[
                      Text(
                        '温度：${session.info!.temperatureCelsius != null ? '${session.info!.temperatureCelsius!.toStringAsFixed(1)} °C' : '不可用'}',
                      ),
                      Text(
                        '电压：${session.info!.voltageVolts != null ? '${session.info!.voltageVolts!.toStringAsFixed(2)} V' : '不可用'}',
                      ),
                    ],
                    Text('健康状态：${session.healthStatus}'),
                    if (session.info?.capacity case final capacity?)
                      _CapacityDetails(capacity: capacity)
                    else
                      const Text('容量诊断：不可用'),
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
            Text('观察控制', style: Theme.of(context).textTheme.titleMedium),
            Text('会话：${session.observationText}'),
            if (session.closeResult != null)
              Text(
                '最近关闭：${session.closeResult!.status == BatteryStatus.closed ? '已释放' : '释放异常'}',
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in BatteryDeliveryMode.values)
                  ChoiceChip(
                    label: Text(
                      mode == BatteryDeliveryMode.changes ? '系统变化' : '定期采样',
                    ),
                    selected: session.mode == mode,
                    onSelected:
                        session.loading ||
                            session.capabilities == null ||
                            !(mode == BatteryDeliveryMode.changes
                                ? session
                                      .capabilities!
                                      .changeObservationSupported
                                : session.capabilities!.observationSupported)
                        ? null
                        : (_) => session.configure(deliveryMode: mode),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _features.entries)
                  FilterChip(
                    label: Text(item.value),
                    selected: session.samples.contains(item.key),
                    onSelected:
                        session.loading ||
                            !session.selectableSamples.contains(item.key)
                        ? null
                        : (selected) {
                            final samples = Set<BatterySample>.of(
                              session.samples,
                            );
                            selected
                                ? samples.add(item.key)
                                : samples.remove(item.key);
                            if (samples.isNotEmpty) {
                              unawaited(session.configure(selection: samples));
                            }
                          },
                  ),
              ],
            ),
            if (session.mode == BatteryDeliveryMode.sampling)
              DropdownButtonFormField<int>(
                initialValue: session.intervalMs,
                decoration: const InputDecoration(labelText: '采样间隔'),
                items: const [
                  DropdownMenuItem(value: 1000, child: Text('1 秒')),
                  DropdownMenuItem(value: 5000, child: Text('5 秒')),
                  DropdownMenuItem(value: 10000, child: Text('10 秒')),
                ],
                onChanged: session.loading
                    ? null
                    : (value) {
                        if (value != null) {
                          unawaited(session.configure(interval: value));
                        }
                      },
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed:
                      session.loading ||
                          !session.modeSupported ||
                          (session.observing &&
                              session.observationState ==
                                  BatteryObservationState.active)
                      ? null
                      : session.start,
                  child: Text(
                    session.observationState ==
                                BatteryObservationState.failed ||
                            session.streamError != null
                        ? '重试监听'
                        : '开始监听',
                  ),
                ),
                OutlinedButton(
                  onPressed: session.loading || !session.observing
                      ? null
                      : session.stop,
                  child: const Text('停止监听'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('系统变化只交付发生变化的状态；定期采样可以重复交付相同读数。观察供电与充电变化时请选择电池信息。'),
            const SizedBox(height: 12),
            Text(
              '最近事件（最多 20 条）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (session.history.isEmpty)
              const Text('暂无事件')
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: session.clearHistory,
                  child: const Text('清空记录'),
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: session.history.length,
                  itemBuilder: (context, index) {
                    final event = session.history[index];
                    final timestamp = event.value?.timestamp;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${event.sample?.name ?? '会话'} · ${event.delivery?.name ?? '状态'} · ${event.status.name}\n'
                        '${timestamp?.toLocal().toIso8601String() ?? '采样时间未知'}'
                        '${event.value == null ? ' · ${event.reason?.code ?? ''}' : ' · ${event.value!.level}% · ${event.value!.chargeState.name}'}',
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('平台能力', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (session.capabilities == null)
              Text(session.loading ? '正在查询平台能力' : '能力查询失败，请刷新重试')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _features.entries)
                    Chip(
                      avatar: Icon(
                        session.capabilities!.supports(item.key)
                            ? Icons.check_circle_outline
                            : Icons.block,
                        size: 18,
                      ),
                      label: Text(
                        '${item.value}：${session.capabilities!.supports(item.key) ? '支持' : '不支持'}',
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            const Text('无电池、未知数据和操作失败分别呈现。'),
          ],
        ),
        sections: const [
          LearningObjectives(
            objectives: [
              '通过独立插件依赖读取真实电池信息',
              '用平台能力查询判断可用操作',
              '比较系统变化通知与定期采样，独立选择观察样本',
              '控制会话启停、重试与页面退出后的资源释放',
              '理解容量单位、来源与未知测量的边界',
            ],
          ),
          ConceptChips(
            concepts: ['插件依赖', 'MethodChannel', 'EventChannel', '能力查询', '资源释放'],
          ),
          CodeSnippetCard(
            title: '先查询能力，再读取状态',
            code:
                'final battery = FlutterBattery();\n'
                'final caps = await battery.capabilities();\n'
                '// 通过 caps.value 检查样本与交付模式支持。\n'
                'final reading = await battery.read();\n'
                'if (reading.isAvailable) {\n'
                '  print(reading.value!.level);\n'
                '} else {\n'
                '  print(reading.status);\n'
                '}\n'
                'final opened = await battery.watchChanges(\n'
                '  options: BatteryChangeOptions(samples: {BatterySample.info}),\n'
                ');\n'
                '// 定期采样使用 sample(BatterySamplingOptions)。\n'
                '// 检查 opened.status；退出时 await opened.value?.close();',
            explanation:
                '能力表示平台接口可用；没有电池或读取失败时仍需呈现明确状态。系统变化监听不轮询；定期采样允许同值交付。切换模式先关闭旧会话，每个会话只释放自己的需求。',
          ),
          CommonPitfalls(
            pitfalls: [
              '无电池或负数读数不能展示为 0% 电量',
              '异步读取完成时，页面可能已退出；避免更新已销毁状态',
              'level 变化不包含电量未变的电源切换；需要供电状态时观察 info',
              '未知容量单位不能计算满充相对设计容量比例',
              '暂停事件订阅不会释放采样需求；停止时应关闭观察会话',
            ],
          ),
          ExerciseCard(
            task: '比较两种模式下同值读数的事件数量，再尝试电量不变时切换供电。',
            hint: '观察 sample、delivery 与供电状态；initial 建立基线，时间戳可能未知。',
          ),
        ],
      ),
    );
  }
}

const _features = {
  BatterySample.level: '电量读取',
  BatterySample.info: '电池信息',
  BatterySample.health: '健康信息',
};

class _CapacityDetails extends StatelessWidget {
  const _CapacityDetails({required this.capacity});
  final BatteryCapacityDetails capacity;

  @override
  Widget build(BuildContext context) {
    final unit = switch (capacity.unit) {
      BatteryCapacityUnit.milliampHours => 'mAh',
      BatteryCapacityUnit.milliwattHours => 'mWh',
      BatteryCapacityUnit.percent => '%',
      BatteryCapacityUnit.unspecified => '单位未知',
    };
    String value(int? measurement) =>
        measurement == null ? '未知' : '$measurement $unit';
    final ratio = capacity.fullChargeRelativeToDesignPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('容量诊断', style: Theme.of(context).textTheme.titleSmall),
        Text('当前容量：${value(capacity.remaining)}'),
        Text('满充容量：${value(capacity.fullCharge)}'),
        Text('设计容量：${value(capacity.design)}'),
        Text('循环次数：${capacity.cycleCount ?? '未知'}'),
        Text(
          '满充 / 设计：${ratio == null ? '不可计算' : '${ratio.toStringAsFixed(1)}%'}',
        ),
        Text('测量来源：${capacity.source}'),
      ],
    );
  }
}
