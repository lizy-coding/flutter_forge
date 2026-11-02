import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'privacy_policy_data.dart';
import 'workbench_history.dart';

class PrivacyDataPanel extends StatelessWidget {
  const PrivacyDataPanel({super.key, required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final history = WorkbenchHistoryScope.maybeOf(context);
    final version = offline ? offlinePrivacyVersion : fullPrivacyVersion;
    final policy = offline ? offlinePrivacyPolicy : fullPrivacyPolicy;
    final email = offline ? offlineSupportEmail : fullSupportEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('隐私与数据', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(offline ? '离线学习版 · 所有实验在本机进行' : '联网完整版 · 按操作使用网络服务'),
        SelectableText('政策版本：$version'),
        ExpansionTile(
          key: ValueKey(
            offline ? 'offline-privacy-notice' : 'full-privacy-notice',
          ),
          title: Text(offline ? '隐私说明与权限用途' : '隐私说明与数据使用'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(policy),
            ),
          ],
        ),
        ExpansionTile(
          key: const ValueKey('privacy-data-controls'),
          title: const Text('管理本地数据与权限'),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最近访问只保存模块入口。清除后不影响主题、实验内容或原有文件。'),
            if (history != null)
              TextButton.icon(
                key: const ValueKey('privacy-clear-recent'),
                onPressed: history.recent.isEmpty
                    ? null
                    : () async {
                        try {
                          await history.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('最近访问已清除')),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('最近访问保存失败，重新打开后可能仍会显示'),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.history),
                label: const Text('清除最近访问'),
              ),
            const SizedBox(height: 12),
            const Text('系统权限：在系统设置中查看或撤销蓝牙、通知等授权。拒绝可选权限不影响其他学习模块。'),
            const SizedBox(height: 12),
            const Text(
              '其他本地数据：Android 可在系统应用设置清除应用数据；Web 可在浏览器清除站点数据。'
              'Windows 的应用重置取决于安装方式；macOS 卸载应用不保证清除全部偏好及网页数据。'
              '清理前请确认需要保留的内容。',
            ),
            if (!offline) ...[
              const SizedBox(height: 12),
              const Text(
                '第三方数据：停止生成、断开连接或离开模块可停止后续操作。'
                '已发送给模型、网页或 Hub 的数据需按服务方规则管理，清除本地数据不会删除服务端数据。',
              ),
            ],
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('复制隐私反馈邮箱'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: email));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('邮箱已复制，请自行发送反馈')));
            }
          },
        ),
      ],
    );
  }
}
