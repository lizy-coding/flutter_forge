import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'notification_session.dart';

/// 系统通知与授权状态：运行时权限、授权请求与本地通知投递。
class SystemNotificationEntry extends StatefulWidget {
  const SystemNotificationEntry({super.key, this.notifications});

  final ForgeNotifications? notifications;

  @override
  State<SystemNotificationEntry> createState() =>
      _SystemNotificationEntryState();
}

class _SystemNotificationEntryState extends State<SystemNotificationEntry> {
  late final NotificationSession session;
  final TextEditingController _titleController = TextEditingController(
    text: '教学通知',
  );
  final TextEditingController _bodyController = TextEditingController(
    text: '这是一条由模块投递的本地通知',
  );
  final TextEditingController _cancelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    session = NotificationSession(widget.notifications ?? ForgeNotifications());
    unawaited(session.initialize());
  }

  @override
  void dispose() {
    session.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _cancelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => LearningScaffold(
        title: '系统通知与授权状态',
        interactiveDemo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(session.permissionText),
            Text('当前状态：${session.permissionStateName}'),
            if (session.loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  (session.capabilities?.permissionRequestSupported ?? false) &&
                      !session.loading
                  ? session.requestPermission
                  : null,
              icon: const Icon(Icons.verified_user),
              label: const Text('请求授权'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '通知标题'),
            ),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: '通知内容'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: session.loading
                  ? null
                  : () => session.post(
                      _titleController.text.trim(),
                      _bodyController.text.trim(),
                    ),
              icon: const Icon(Icons.notifications_active),
              label: const Text('投递通知'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cancelController,
                    decoration: const InputDecoration(labelText: '日志中的通知 id'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: session.loading
                      ? null
                      : () => session.cancel(_cancelController.text),
                  child: const Text('撤回'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StateLogView(logs: session.logs),
          ],
        ),
        sections: const [
          LearningObjectives(
            objectives: [
              '理解授权状态是运行时事实：模块入口开放不代表系统已授予通知权限',
              '观察 Android 13+ 的 POST_NOTIFICATIONS 授权请求与 macOS 授权询问的差异',
              '掌握投递失败的原因码：permissionDenied 与 notDetermined 指向不同操作',
            ],
          ),
          CommonPitfalls(
            pitfalls: [
              '「请求授权」返回 granted 只是当次结果，系统设置里随时可以再关闭，投递前应重新查询',
              'Android 13 之前没有运行时通知权限，授权状态来自「通知开关」而不是权限对话框',
              'macOS 的授权结果需要重新读取通知设置，requestAuthorization 的布尔值不是最终状态',
              '通知需要 smallIcon（Android）与前台运行时上下文，缺失会直接投递失败',
            ],
          ),
          ExerciseCard(
            task: '在拒绝授权后投递一次通知，再授权后重新投递，对比两次原因码',
            hint:
                '拒绝后投递返回 permissionDenied/post_notifications_denied；授权后返回 available 并给出可撤回的 id',
          ),
        ],
      ),
    );
  }
}
