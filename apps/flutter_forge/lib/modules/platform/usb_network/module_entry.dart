import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:usb_network_bridge/usb_network_bridge.dart';

import 'usb_network_session.dart';

class UsbNetworkEntry extends StatefulWidget {
  const UsbNetworkEntry({super.key, this.adapter});
  final UsbNetworkAdapter? adapter;
  @override
  State<UsbNetworkEntry> createState() => _UsbNetworkEntryState();
}

class _UsbNetworkEntryState extends State<UsbNetworkEntry> {
  late final UsbNetworkSession session;
  final host = TextEditingController();
  final port = TextEditingController(text: '9001');
  final message = TextEditingController(text: 'hello');
  bool appendNewline = true;

  @override
  void initState() {
    super.initState();
    session = UsbNetworkSession(widget.adapter ?? createUsbNetworkAdapter());
  }

  @override
  void dispose() {
    session.dispose();
    host.dispose();
    port.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => LearningScaffold(
      title: 'USB 网络连接基础',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            session.status,
            key: const Key('usb-status'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: session.busy || session.connected
                  ? null
                  : session.scan,
              icon: const Icon(Icons.usb),
              label: const Text('扫描 NCM 网卡'),
            ),
          ),
          const SizedBox(height: 12),
          if (session.interfaces.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(session.selected?.key),
              initialValue: session.selected?.key,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'USB 网络接口',
                border: OutlineInputBorder(),
              ),
              items: session.interfaces
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.key,
                      child: Text(
                        '${item.name} · ${item.address}/${item.prefix}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: session.busy || session.connected
                  ? null
                  : (key) {
                      if (key != null) session.select(key);
                    },
            ),
          if (session.selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '接口索引 ${session.selected!.index} · ${session.selected!.id}',
              ),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final addressField = TextField(
                controller: host,
                enabled: !session.busy && !session.connected,
                key: const Key('usb-host'),
                decoration: const InputDecoration(
                  labelText: '设备 IPv4',
                  hintText: '填写设备 USB 网口地址',
                  border: OutlineInputBorder(),
                ),
              );
              final portField = TextField(
                controller: port,
                enabled: !session.busy && !session.connected,
                key: const Key('usb-port'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'TCP 端口',
                  border: OutlineInputBorder(),
                ),
              );
              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    addressField,
                    const SizedBox(height: 12),
                    portField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: addressField),
                  const SizedBox(width: 12),
                  SizedBox(width: 140, child: portField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed:
                    session.busy ||
                        session.connected ||
                        session.selected == null
                    ? null
                    : () => session.connect(host.text, port.text),
                child: const Text('连接'),
              ),
              OutlinedButton(
                onPressed: session.connected || session.busy
                    ? session.disconnect
                    : null,
                child: const Text('断开'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: message,
            key: const Key('usb-message'),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '发送 UTF-8 文本',
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('末尾追加换行'),
            value: appendNewline,
            onChanged: (value) => setState(() => appendNewline = value ?? true),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: session.connected && !session.sending
                  ? () =>
                        session.send(message.text, appendNewline: appendNewline)
                  : null,
              child: const Text('发送'),
            ),
          ),
          const SizedBox(height: 16),
          Text('收发日志（最近 100 条）', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: session.logs.isEmpty
                ? const Text('等待操作')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: session.logs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(session.logs[index]),
                    ),
                  ),
          ),
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '观察系统驱动提供的 USB CDC-NCM 网卡。',
            '将 TCP 连接固定到选择的 USB 接口与本地 IPv4。',
            '观察收发字节、连接失败和资源释放。',
          ],
        ),
        ConceptChips(concepts: ['CDC-NCM', 'IPv4', '接口绑定', 'TCP 字节流', '资源释放']),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '连接前请插入支持 CDC-NCM 的设备，确认系统已有驱动和可用 IPv4。设备端需要提供 TCP 服务；'
            '只有回显服务才会原样返回 hello。TCP 接收块不是完整消息。'
            '\n本页只发送原始 TCP 文本，不执行 WebSocket 握手或设备专有协议，9001 仅为可修改的端口初值。'
            '\n未发现接口、目标拒绝连接和拔线均显示实际状态；断线后需要手动重新扫描、连接。',
          ),
        ),
      ],
    ),
  );
}
