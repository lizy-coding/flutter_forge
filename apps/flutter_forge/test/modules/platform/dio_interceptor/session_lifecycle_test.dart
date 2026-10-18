import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/mock_server/mock_server.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/lesson_session.dart';

class _RealIo extends io.HttpOverrides {}

Future<void> realIo(Future<void> Function() body) =>
    io.HttpOverrides.runWithHttpOverrides(body, _RealIo());
MockServer quietServer() => MockServer()
  ..failureRate = 0
  ..networkDelay = 0;

void main() {
  test(
    'stopping during bind closes the late server before stop completes',
    () async {
      final reservation = await io.ServerSocket.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final server = MockServer(port: port);
      final opening = server.start();
      await server.stop();
      await opening;
      final replacement = await io.ServerSocket.bind(
        io.InternetAddress.loopbackIPv4,
        port,
      );
      await replacement.close();
      expect(() => server.baseUrl, throwsStateError);
      await expectLater(server.start(), throwsStateError);
      await server.stop();
    },
  );

  test(
    'independent servers use independent ports, tokens and lifetimes',
    () => realIo(() async {
      final first = quietServer();
      final second = quietServer();
      Dio? a;
      Dio? b;
      try {
        await Future.wait([first.start(), second.start()]);
        expect(first.baseUrl, isNot(second.baseUrl));
        a = Dio(BaseOptions(baseUrl: first.baseUrl));
        b = Dio(BaseOptions(baseUrl: second.baseUrl));
        final login = await a.post<Map<String, dynamic>>(
          '/api/login',
          data: {'username': 'admin', 'password': 'password123'},
        );
        final token = login.data!['data']['token'] as String;
        await expectLater(
          b.get<dynamic>(
            '/api/articles',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          ),
          throwsA(isA<DioException>()),
        );
        await first.stop();
        final other = await b.post<dynamic>(
          '/api/login',
          data: {'username': 'admin', 'password': 'password123'},
        );
        expect(other.statusCode, 200);
      } finally {
        a?.close(force: true);
        b?.close(force: true);
        await first.stop();
        await second.stop();
      }
    }),
  );

  test('bind failures remain visible to the session owner', () async {
    final occupied = await io.ServerSocket.bind(
      io.InternetAddress.loopbackIPv4,
      0,
    );
    final server = MockServer(port: occupied.port);
    try {
      await expectLater(server.start(), throwsA(isA<io.SocketException>()));
    } finally {
      await server.stop();
      await occupied.close();
    }
  });

  test(
    'page leases keep the session alive until the last page leaves',
    () => realIo(() async {
      final server = quietServer();
      final first = LessonSession.acquire(createServer: () => server);
      final second = LessonSession.acquire();
      try {
        await Future.wait([first.ready, second.ready]);
        expect(first.api, same(second.api));
        final api = second.api;
        await first.close();
        expect(() => first.api, throwsStateError);
        final login = await api.login('admin', 'password123');
        api.setToken(login['data']['token'] as String);
        expect((await api.getArticles())['success'], isTrue);
        final port = Uri.parse(server.baseUrl).port;
        await second.close();
        final replacement = await io.ServerSocket.bind(
          io.InternetAddress.loopbackIPv4,
          port,
        );
        await replacement.close();
        final fresh = LessonSession.acquire(createServer: quietServer);
        try {
          await fresh.ready;
          expect(fresh.api, isNot(same(api)));
          expect(fresh.api.isLoggedIn, isFalse);
        } finally {
          await fresh.close();
        }
      } finally {
        await first.close();
        await second.close();
      }
    }),
  );
}
