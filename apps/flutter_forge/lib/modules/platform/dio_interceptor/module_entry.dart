import 'package:flutter/material.dart';

import 'mock_server/mock_server.dart';
import 'pages/home_page.dart' as interceptor_test;

class InterceptorTestEntry extends StatefulWidget {
  const InterceptorTestEntry({super.key});

  @override
  State<InterceptorTestEntry> createState() => _InterceptorTestEntryState();
}

class _InterceptorTestEntryState extends State<InterceptorTestEntry> {
  final MockServer _server = MockServer();
  late final Future<void> _startFuture;

  @override
  void initState() {
    super.initState();
    _startFuture = _server.start();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingPage(title: 'Starting mock server');
        }
        return const interceptor_test.HomePage();
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
