import 'dart:async';

enum DiagnosticSymptom {
  offline('无法上网'),
  target('指定目标不可达'),
  intermittent('慢／间歇失败');

  const DiagnosticSymptom(this.label);
  final String label;
}

class DiagnosticTarget {
  const DiagnosticTarget(this.uri);
  final Uri uri;

  static const defaults = 'https://www.baidu.com/\nhttps://www.bing.com/';

  static List<DiagnosticTarget> parseLines(String input) {
    final lines = input
        .split('\n')
        .map((line) => line.trim())
        .where((s) => s.isNotEmpty);
    final targets = <DiagnosticTarget>[];
    for (final line in lines) {
      final uri = Uri.tryParse(line.contains('://') ? line : 'https://$line');
      if (uri == null ||
          RegExp(r'\s').hasMatch(line) ||
          !['http', 'https', 'tcp'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.host.contains('%') ||
          uri.host.contains(RegExp(r'\s')) ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          uri.port < 1 ||
          uri.port > 65535 ||
          (uri.scheme == 'tcp' &&
              (!uri.hasPort || (uri.path.isNotEmpty && uri.path != '/')))) {
        throw const FormatException(
          '请输入 HTTP(S) 地址或 tcp://主机:端口；不包含账号、查询参数或片段。',
        );
      }
      if (!targets.any((target) => target.uri == uri)) {
        targets.add(DiagnosticTarget(uri));
      }
    }
    if (targets.isEmpty || targets.length > 4) {
      throw const FormatException('请输入 1～4 个不同目标，每行一个。');
    }
    return List.unmodifiable(targets);
  }

  bool get isTcp => uri.scheme == 'tcp';
}

enum ProbeStage { dns, tcp, http }

enum ProbeOutcome { success, failure, skipped }

class ProbeReading {
  const ProbeReading({
    required this.stage,
    required this.outcome,
    required this.elapsed,
    required this.detail,
    this.addresses = const [],
    this.statusCode,
  });

  final ProbeStage stage;
  final ProbeOutcome outcome;
  final Duration elapsed;
  final String detail;
  final List<String> addresses;
  final int? statusCode;

  String get label => switch (stage) {
    ProbeStage.dns => 'DNS 解析',
    ProbeStage.tcp => 'TCP 连接',
    ProbeStage.http => 'HTTP 响应',
  };
}

class ProbeSample {
  const ProbeSample({
    required this.target,
    required this.round,
    required this.readings,
    this.securityChecks = const [],
  });
  final DiagnosticTarget target;
  final int round;
  final List<ProbeReading> readings;
  final List<DiagnosticCheck> securityChecks;

  // Any HTTP status proves a response, not that the application works correctly.
  bool get reached => readings.last.outcome == ProbeOutcome.success;
  bool get applicationWarning =>
      readings.any((r) => (r.statusCode ?? 0) >= 400);
}

class NetworkSnapshot {
  const NetworkSnapshot({
    required this.system,
    required this.interfaces,
    this.note,
    this.vpn = const DiagnosticCheck(
      "VPN／隧道",
      CheckLevel.unknown,
      "未取得网卡证据，无法判断 VPN 状态。",
    ),
    this.dnsIntegrity = const DiagnosticCheck(
      "DNS 劫持线索",
      CheckLevel.unknown,
      "未执行异常解析检测。",
    ),
  });
  final String system;
  final List<String> interfaces;
  final String? note;
  final DiagnosticCheck vpn;
  final DiagnosticCheck dnsIntegrity;
}

class DiagnosticCancelled implements Exception {
  const DiagnosticCancelled();
}

/// Cancellation races pending reads and closes registered sockets and clients.
class DiagnosticCancellation {
  final _cancelled = Completer<void>();
  final _cleanup = <void Function()>{};
  bool get isCancelled => _cancelled.isCompleted;

  void check() {
    if (isCancelled) throw const DiagnosticCancelled();
  }

  void Function() register(void Function() cleanup) {
    if (isCancelled) {
      cleanup();
    } else {
      _cleanup.add(cleanup);
    }
    return () => _cleanup.remove(cleanup);
  }

  void cancel() {
    if (isCancelled) return;
    _cancelled.complete();
    for (final cleanup in _cleanup.toList()) {
      cleanup();
    }
    _cleanup.clear();
  }

  Future<T> wait<T>(Future<T> operation, Duration timeout) async {
    check();
    final deadline = Completer<T>();
    final timer = Timer(
      timeout,
      () => deadline.completeError(TimeoutException('检测超时')),
    );
    // Register removable callbacks; repeated samples must not retain listeners.
    final remove = register(() {
      if (!deadline.isCompleted) {
        deadline.completeError(const DiagnosticCancelled());
      }
    });
    try {
      return await Future.any([operation, deadline.future]);
    } finally {
      timer.cancel();
      remove();
    }
  }
}

enum CheckLevel { unknown, noSignal, notice, suspicious }

class DiagnosticCheck {
  const DiagnosticCheck(this.title, this.level, this.detail);
  final String title;
  final CheckLevel level;
  final String detail;
  String get label => switch (level) {
    CheckLevel.unknown => '无法判断',
    CheckLevel.noSignal => '未发现该线索',
    CheckLevel.notice => '需核对',
    CheckLevel.suspicious => '发现可疑线索',
  };
  String get text => '$title · $label：$detail';
}
