import 'dart:async';

import 'package:flutter/material.dart';

import 'lesson_session.dart';
import 'pages/home_page.dart' as interceptor_test;

class InterceptorTestEntry extends StatefulWidget {
  const InterceptorTestEntry({super.key});

  @override
  State<InterceptorTestEntry> createState() => _InterceptorTestEntryState();
}

class _InterceptorTestEntryState extends State<InterceptorTestEntry> {
  late LessonLease _lease;

  @override
  void initState() {
    super.initState();
    _lease = LessonSession.acquire();
  }

  @override
  void dispose() {
    unawaited(_lease.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _lease.ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingPage(title: 'Starting mock server');
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dio 拦截器演示')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('模拟服务启动失败，请重试。'),
                  TextButton(
                    onPressed: () {
                      unawaited(_lease.close());
                      setState(() => _lease = LessonSession.acquire());
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        return interceptor_test.HomePage(api: _lease.api);
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
