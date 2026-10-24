import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_articles/forge_articles.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';

class WorkflowSession extends ChangeNotifier {
  WorkflowSession({String? executorId, ArticleWorkflowRunner? runner})
    : executorId =
          executorId ?? 'forge-${DateTime.now().microsecondsSinceEpoch}',
      _runner = runner ?? ArticleWorkflowRunner();

  final String executorId;
  final ArticleWorkflowRunner _runner;
  WorkflowHubClient? _hub;
  Timer? _timer;
  CancelToken? _cancel;
  Future<void>? _execution;
  bool _polling = false;
  bool _disposed = false;
  bool _submitting = false;
  bool connecting = false;
  int _generation = 0;
  int _counter = 0;
  Map<String, dynamic>? definition;
  Map<String, dynamic>? current;
  Map<String, dynamic> inputs = {};
  List<Map<String, dynamic>> history = [];
  String? error;
  bool get connected => _hub != null;
  bool get busy =>
      _submitting ||
      _execution != null ||
      ['queued', 'running', 'cancelling'].contains(current?['state']);
  String get state => current?['state'] as String? ?? 'idle';

  Future<void> connect(WorkflowHubClient hub) async {
    if (busy || connecting) {
      hub.close();
      return;
    }
    final generation = ++_generation;
    connecting = true;
    error = null;
    _notify();
    try {
      final response = await hub.workflows();
      final candidates = (response['workflows'] as List).where(
        (row) =>
            row is Map &&
            row['id'] == 'articles.explore' &&
            row['version'] == 1,
      );
      if (candidates.length != 1) {
        throw const FormatException('Hub 缺少已支持的文章流程版本。');
      }
      final flow = Map<String, dynamic>.from(candidates.single as Map);
      await hub.register(executorId, articleCapabilities);
      if (_disposed || generation != _generation) {
        hub.close();
        return;
      }
      _timer?.cancel();
      _hub?.close();
      _hub = hub;
      definition = flow;
      final properties = (flow['inputSchema'] as Map)['properties'] as Map;
      inputs = {
        for (final entry in properties.entries)
          entry.key as String: (entry.value as Map)['default'],
      };
      current = null;
      history = [];
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(poll()),
      );
    } catch (e) {
      hub.close();
      if (!_disposed && generation == _generation) error = _message(e);
    } finally {
      if (!_disposed && generation == _generation) {
        connecting = false;
        _notify();
      }
    }
    if (connected) await poll();
  }

  void parameter(String key, Object value) {
    if (busy || !inputs.containsKey(key)) return;
    inputs = {...inputs, key: value};
    _notify();
  }

  Future<void> submit() async {
    final hub = _hub;
    final flow = definition;
    if (hub == null || flow == null || busy || _disposed) return;
    _submitting = true;
    error = null;
    _notify();
    try {
      final retryOf = ['failed', 'cancelled'].contains(state)
          ? (current?['id'] as String?)
          : null;
      final run = await hub.create(
        executorId,
        'request-${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
        flow,
        Map.of(inputs),
        retryOf: retryOf,
      );
      if (!_disposed && identical(hub, _hub)) _adopt(run);
    } catch (e) {
      if (!_disposed) error = _message(e);
    } finally {
      _submitting = false;
      _notify();
    }
    await poll();
  }

  Future<void> poll() async {
    final hub = _hub;
    if (_disposed || hub == null || _polling || connecting) return;
    final generation = _generation;
    _polling = true;
    try {
      if (_execution == null) {
        final claim = await hub.claim(executorId);
        if (_disposed || generation != _generation) return;
        if (claim.isNotEmpty) {
          _execution = _execute(hub, claim, generation);
          unawaited(_execution);
        } else if (current != null &&
            ['queued', 'running', 'cancelling'].contains(state)) {
          final updated = await hub.run(current!['id'] as String);
          if (_disposed || generation != _generation) return;
          _adopt(updated);
        }
      } else if (current != null) {
        final updated = await hub.run(current!['id'] as String);
        if (_disposed || generation != _generation) return;
        _adopt(updated);
        if (updated['state'] == 'cancelling' ||
            updated['state'] == 'cancelled') {
          _cancel?.cancel('hub cancellation');
        }
      }
      final rows = await hub.history(executorId);
      if (_disposed || generation != _generation) return;
      history = rows;
    } catch (e) {
      if (!_disposed && generation == _generation) error = _message(e);
    } finally {
      _polling = false;
      _notify();
    }
  }

  Future<void> _execute(
    WorkflowHubClient hub,
    Map<String, dynamic> claim,
    int generation,
  ) async {
    final token = _cancel = CancelToken();
    final id = claim['id'] as String;
    final lease = claim['leaseToken'] as String;
    var sequence = 0;
    _adopt(Map.of(claim)..remove('leaseToken'));
    _notify();
    Future<void> emit(Map<String, dynamic> event) async {
      final run = await hub.event(
        id,
        executorId,
        lease,
        'event-${++sequence}',
        event,
      );
      if (!_disposed && generation == _generation) {
        _adopt(run);
        _notify();
      }
    }

    try {
      final result = await _runner.run(
        definition: Map<String, dynamic>.from(claim['definition'] as Map),
        inputs: Map<String, dynamic>.from(claim['inputs'] as Map),
        cancelToken: token,
        emit: (kind, step) => emit({'kind': kind, 'stepId': step}),
      );
      if (token.isCancelled) throw token.cancelError!;
      await emit({'kind': 'succeeded', 'result': result});
    } catch (e) {
      try {
        final remote = await hub.run(id);
        if (!['succeeded', 'failed', 'cancelled'].contains(remote['state'])) {
          final cancelled =
              token.isCancelled || remote['state'] == 'cancelling';
          await emit({
            'kind': cancelled ? 'cancelled' : 'failed',
            'message': cancelled ? '使用者取消或执行端离开' : _message(e),
          });
        } else if (!_disposed && generation == _generation) {
          _adopt(remote);
        }
      } catch (_) {
        if (!_disposed && generation == _generation) {
          error = '执行已停止，Hub 暂不可达；运行将由租约超时结束。';
        }
      }
    } finally {
      if (generation == _generation) {
        _execution = null;
        _cancel = null;
      }
      _notify();
    }
  }

  Future<void> cancel() async {
    final id = current?['id'] as String?;
    final hub = _hub;
    if (hub == null || id == null || !busy) return;
    _cancel?.cancel('user cancellation');
    try {
      final run = await hub.cancel(id);
      if (!_disposed) _adopt(run);
    } catch (e) {
      if (!_disposed) error = _message(e);
    }
    _notify();
  }

  Future<void> select(String id) async {
    if (busy || _hub == null) return;
    try {
      final run = await _hub!.run(id);
      if (!_disposed) _adopt(run);
    } catch (e) {
      if (!_disposed) error = _message(e);
    }
    _notify();
  }

  String _message(Object error) {
    if (error is FormatException) return error.message;
    if (error is DioException) {
      return switch (error.response?.statusCode) {
        401 || 403 => 'Hub 认证失败，请检查临时访问令牌和浏览器来源。',
        409 => '运行状态或版本冲突，请刷新 Hub 记录。',
        503 => '教学故障：文章请求失败。',
        _ => 'Hub 或数据请求失败，请检查连接后重试。',
      };
    }
    return '工作流执行失败。';
  }

  void _adopt(Map<String, dynamic> run) {
    if (current?['id'] == run['id'] &&
        ((run['events'] as List?)?.length ?? 0) <
            ((current?['events'] as List?)?.length ?? 0)) {
      return;
    }
    current = run;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> shutdown() async {
    _timer?.cancel();
    _cancel?.cancel('executor closed');
    final hub = _hub;
    final id = current?['id'] as String?;
    if (hub != null && id != null && busy) {
      try {
        await hub.cancel(id);
      } catch (_) {
        /* Lease expiry remains authoritative. */
      }
    }
    try {
      await _execution?.timeout(const Duration(seconds: 6));
    } catch (_) {
      /* Hub expires abandoned work. */
    }
    hub?.close();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(shutdown());
    super.dispose();
  }
}
