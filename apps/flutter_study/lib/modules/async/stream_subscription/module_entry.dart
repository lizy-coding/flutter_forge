import 'package:flutter/material.dart';

import 'pages/home_page.dart' as stream_subscription;

class StreamSubscriptionEntry extends StatelessWidget {
  const StreamSubscriptionEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const stream_subscription.HomePage();
  }
}
