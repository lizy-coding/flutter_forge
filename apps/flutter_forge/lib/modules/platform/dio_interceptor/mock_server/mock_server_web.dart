/// Web uses an in-memory Dio adapter, so no localhost server is started.
class MockServer {
  String get baseUrl => 'http://lesson.local';
  Future<void> start() async {}
  Future<void> stop() async {}
}
