import 'package:flutter_forge_app/l10n/strings.dart';
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
        Text(
          appStrings(context).privacyData,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          offline
              ? appStrings(context).offlineEdition
              : appStrings(context).fullEdition,
        ),
        SelectableText(appStrings(context).policyVersion(version)),
        ExpansionTile(
          key: ValueKey(
            offline ? 'offline-privacy-notice' : 'full-privacy-notice',
          ),
          title: Text(
            offline
                ? appStrings(context).privacyPermissions
                : appStrings(context).privacyUsage,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appStrings(context).policyChinese),
                  SelectableText(policy),
                ],
              ),
            ),
          ],
        ),
        ExpansionTile(
          key: const ValueKey('privacy-data-controls'),
          title: Text(appStrings(context).manageData),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appStrings(context).recentScope),
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
                              SnackBar(
                                content: Text(
                                  appStrings(context).recentCleared,
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  appStrings(context).recentSaveFailed,
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.history),
                label: Text(appStrings(context).clearRecent),
              ),
            const SizedBox(height: 12),
            Text(appStrings(context).systemPermissions),
            const SizedBox(height: 12),
            Text(appStrings(context).otherData),
            if (!offline) ...[
              const SizedBox(height: 12),
              Text(appStrings(context).thirdPartyData),
            ],
          ],
        ),
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: Text(appStrings(context).copyPrivacyEmail),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: email));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appStrings(context).emailCopied)),
              );
            }
          },
        ),
      ],
    );
  }
}
