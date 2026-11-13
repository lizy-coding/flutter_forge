import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mixin.one/desktop_multi_window');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('Windows startup waits for child channel registration', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      if (++calls < 3) throw MissingPluginException();
      return {'windowId': 'child', 'windowArgument': 'category:basic'};
    });
    final window = await WindowController.fromCurrentEngine();
    expect(window.windowId, 'child');
    expect(window.arguments, 'category:basic');
    expect(calls, 3);
  });

  test('Windows missing plugin wait is bounded', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      throw MissingPluginException();
    });
    await expectLater(
      WindowController.fromCurrentEngine(),
      throwsA(isA<MissingPluginException>()),
    );
    expect(calls, 41);
  });

  test('startup propagates platform failures without retry', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      throw PlatformException(code: 'broken');
    });
    await expectLater(
      WindowController.fromCurrentEngine(),
      throwsA(isA<PlatformException>()),
    );
    expect(calls, 1);
  });

  test('other platforms do not retry missing plugins', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      throw MissingPluginException();
    });
    await expectLater(
      WindowController.fromCurrentEngine(),
      throwsA(isA<MissingPluginException>()),
    );
    expect(calls, 1);
  });

  test('an unresponsive native startup channel times out', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    messenger.setMockMethodCallHandler(
      channel,
      (_) => Completer<Object?>().future,
    );
    await expectLater(
      WindowController.fromCurrentEngine(),
      throwsA(isA<TimeoutException>()),
    );
  });

  for (final definition in [
    null,
    <String, Object?>{},
    {'windowId': '', 'windowArgument': ''},
    {'windowId': 'child', 'windowArgument': 42},
  ]) {
    test('invalid window definition fails explicitly: $definition', () async {
      messenger.setMockMethodCallHandler(channel, (_) async => definition);
      await expectLater(
        WindowController.fromCurrentEngine(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'WINDOW_DEFINITION_INVALID',
          ),
        ),
      );
    });
  }

  for (final invalidId in [null, '']) {
    test(
      'creation rejects invalid native identity $invalidId at runtime',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async => invalidId);
        await expectLater(
          WindowController.create(const WindowConfiguration(arguments: '')),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'WINDOW_CREATION_FAILED',
            ),
          ),
        );
      },
    );
  }

  test(
    'startup frame barrier and native close target the correct window',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'window_isReadyToShow' ? true : null;
      });
      final controller = WindowController.fromWindowId('starting-window');
      await controller.markReady();
      expect(await controller.isReadyToShow(), isTrue);
      await controller.closeNative();
      expect(calls.map((call) => call.method), [
        'window_markReady',
        'window_isReadyToShow',
        'window_close',
      ]);
      expect(
        calls.every(
          (call) => (call.arguments as Map)['windowId'] == 'starting-window',
        ),
        isTrue,
      );
    },
  );

  test(
    'child GPU configuration is opt-in and reaches native creation',
    () async {
      expect(WindowConfiguration.fromJson({}).enableFlutterGpu, isFalse);
      const config = WindowConfiguration(
        arguments: 'category:ui',
        enableFlutterGpu: true,
      );
      expect(WindowConfiguration.fromJson(config.toJson()), config);
      expect(
        config,
        isNot(const WindowConfiguration(arguments: 'category:ui')),
      );
      MethodCall? created;
      messenger.setMockMethodCallHandler(channel, (call) async {
        created = call;
        return 'gpu-window';
      });
      await WindowController.create(config);
      expect(created!.method, 'createWindow');
      expect((created!.arguments as Map)['enableFlutterGpu'], isTrue);
    },
  );

  test('missing native window inventory yields an empty list', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await WindowController.getAll(), isEmpty);
  });

  test(
    'window inventory preserves identities and routes show to its window',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'getAllWindows') {
          return [
            {'windowId': '42', 'windowArgument': 'category:basic'},
          ];
        }
        return null;
      });
      final windows = await WindowController.getAll();
      expect(windows.single.windowId, '42');
      expect(windows.single.arguments, 'category:basic');
      await windows.single.show();
      expect(calls.last.method, 'window_show');
      expect(calls.last.arguments, {'windowId': '42'});
    },
  );

  test('native failures remain observable', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(WindowController.getAll(), throwsA(isA<PlatformException>()));
  });
}
