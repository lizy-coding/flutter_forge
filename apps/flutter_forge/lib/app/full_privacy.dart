import 'package:flutter/material.dart';

import 'privacy_data_panel.dart';

export 'privacy_policy_data.dart'
    show fullPrivacyPolicy, fullPrivacyVersion, fullSupportEmail;

class FullPrivacy extends StatelessWidget {
  const FullPrivacy({super.key});

  @override
  Widget build(BuildContext context) => const PrivacyDataPanel(offline: false);
}
