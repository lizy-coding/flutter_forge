import 'package:flutter/material.dart';

import 'privacy_data_panel.dart';

export 'privacy_policy_data.dart'
    show offlinePrivacyPolicy, offlinePrivacyVersion, offlineSupportEmail;

class OfflinePrivacy extends StatelessWidget {
  const OfflinePrivacy({super.key});

  @override
  Widget build(BuildContext context) => const PrivacyDataPanel(offline: true);
}
