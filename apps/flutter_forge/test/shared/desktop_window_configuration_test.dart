import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  setUp(() {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('content')),
        ),
      ],
    );
  });
  tearDown(() {
    router.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DesktopWindowHost.channel, null);
  });

  Future<void> pumpHost(WidgetTester tester, {String title = 'A'}) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => DesktopWindowHost(
          router: router,
          modules: const [],
          themeMode: ThemeMode.light,
          platform: const AppPlatformSnapshot(
            platform: AppTargetPlatform.windows,
          ),
          title: title,
          child: child!,
        ),
      ),
    );
    await tester.pump();
  }

  DesktopWindowController controller(WidgetTester tester) =>
      DesktopWindowScope.maybeOf(tester.element(find.text('content')))!;

  testWidgets(
    'missing plugin and platform errors retry the same configuration',
    (tester) async {
      var attempts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (_) async {
          if (++attempts == 1) throw MissingPluginException();
          if (attempts == 2) {
            throw PlatformException(code: 'temporarily_unavailable');
          }
          return {'active': true};
        },
      );
      await pumpHost(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(attempts, 3);
      expect(controller(tester).ready, isTrue);
      expect(find.byKey(const ValueKey('desktop-window-retry')), findsNothing);
    },
  );

  testWidgets(
    'exhausted retries offer an explicit retry without changing the route',
    (tester) async {
      var fail = true;
      var attempts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (_) async {
          attempts++;
          if (fail) throw PlatformException(code: 'unavailable');
          return {'active': true};
        },
      );
      await pumpHost(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(attempts, 3);
      expect(controller(tester).ready, isFalse);
      fail = false;
      await tester.tap(find.byKey(const ValueKey('desktop-window-retry')));
      await tester.pumpAndSettle();
      expect(attempts, 4);
      expect(controller(tester).ready, isTrue);
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byKey(const ValueKey('desktop-window-retry')), findsNothing);
    },
  );

  testWidgets(
    'timeout retries and a late response cannot overwrite newer native state',
    (tester) async {
      final lateResponse = Completer<Map<String, Object>>();
      var attempts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (_) async {
          if (++attempts == 1) return lateResponse.future;
          return {'fullscreen': false};
        },
      );
      await pumpHost(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(attempts, 2);
      expect(controller(tester).ready, isTrue);
      lateResponse.complete({'fullscreen': true});
      await tester.pump();
      expect(controller(tester).fullscreen, isFalse);
    },
  );

  testWidgets(
    'returning to the saved configuration while a request is pending resends the latest value',
    (tester) async {
      final pending = Completer<Map<String, Object>>();
      final titles = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (call) async {
          titles.add((call.arguments as Map)['title']);
          if (titles.length == 2) return pending.future;
          return {'active': true};
        },
      );
      await pumpHost(tester);
      await pumpHost(tester, title: 'B');
      await pumpHost(tester);
      pending.complete({'active': false});
      await tester.pumpAndSettle();
      expect(titles, ['A', 'B', 'A']);
      expect(controller(tester).active, isTrue);
    },
  );

  testWidgets(
    'disposing an in-flight configuration cancels timers and ignores its response',
    (tester) async {
      final pending = Completer<Map<String, Object>>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (_) => pending.future,
      );
      await pumpHost(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete({'active': true});
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed configuration cannot suppress returning to an earlier success',
    (tester) async {
      final titles = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (call) async {
          final title = (call.arguments as Map)['title'];
          titles.add(title);
          if (title == 'B') throw PlatformException(code: 'partial_failure');
          return {'active': true};
        },
      );
      await pumpHost(tester);
      await pumpHost(tester, title: 'B');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('desktop-window-retry')),
        findsOneWidget,
      );
      await pumpHost(tester);
      expect(titles, ['A', 'B', 'B', 'B', 'A']);
      expect(find.byKey(const ValueKey('desktop-window-retry')), findsNothing);
    },
  );
}
