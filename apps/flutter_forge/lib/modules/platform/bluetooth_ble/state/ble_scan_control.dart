part of 'ble_session.dart';

/// Scan round control: start/stop with confirmation, stale-result aging and
/// history cleanup. Shares the session's generation counters so a late
/// adapter callback can never resurrect a finished round.
extension BleScanControl on BleSession {
  bool get scanning =>
      scanPhase == BleScanPhase.running ||
      scanPhase == BleScanPhase.stopping ||
      scanPhase == BleScanPhase.unconfirmed;
  bool get canStartScan =>
      !_closed &&
      !busy &&
      !scanning &&
      _active &&
      connectedId == null &&
      linkPhase != BleLinkPhase.disconnectUnconfirmed &&
      availabilityState != AvailabilityState.poweredOff &&
      availabilityState != AvailabilityState.unsupported &&
      availabilityState != AvailabilityState.resetting;
  int get scanSecondsRemaining {
    final remaining = _scanDeadline?.difference(_now()).inMilliseconds ?? 0;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  Duration? ageOf(String id) {
    final seen = lastSeen[id];
    return seen == null ? null : _now().difference(seen);
  }

  BleAdvertisementState advertisementState(String id) {
    final age = ageOf(id);
    if (age == null || age >= staleAfter) return BleAdvertisementState.expired;
    return currentRoundIds.contains(id)
        ? BleAdvertisementState.currentRound
        : BleAdvertisementState.previousRound;
  }

  Future<void> startScan({Duration? duration}) async {
    if (!canStartScan) return;
    final limit = duration ?? scanDuration;
    if (limit <= Duration.zero || limit > const Duration(seconds: 60)) {
      error = '扫描时长应大于 0 且不超过 60 秒';
      _notify();
      return;
    }
    final generation = ++_scanGeneration;
    _scanStartInFlight = true;
    scanPhase = BleScanPhase.starting;
    currentRoundIds.clear();
    error = null;
    scanSummary = '正在检查权限并启动扫描';
    _notify();
    var nativeRequested = false;
    try {
      await client.requestPermissions().timeout(operationLimit);
      final granted = await client.hasPermissions().timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) return;
      permissionGranted = granted;
      if (!granted) throw StateError('蓝牙权限未授予');
      final state = await client.availability().timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) return;
      _applyAvailability(state);
      if (state != AvailabilityState.poweredOn) throw StateError('请先开启蓝牙');
      nativeRequested = true;
      final nativeStart = client.startScan();
      unawaited(
        nativeStart.then<void>((_) {
          if (_closed ||
              generation != _scanGeneration ||
              scanPhase == BleScanPhase.idle ||
              scanPhase == BleScanPhase.unconfirmed) {
            unawaited(_releaseLateScan(generation));
          }
        }, onError: (Object error, StackTrace stack) {}),
      );
      await nativeStart.timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) {
        return;
      }
      scanPhase = BleScanPhase.running;
      _scanDeadline = _now().add(limit);
      scanSummary = '扫描中';
      _startHeartbeat();
      _log('开始扫描，${limit.inSeconds} 秒后自动停止；保留历史结果');
      _scanTimer = Timer(limit, () => stopScan(reason: '限时结束'));
    } catch (e) {
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.idle;
      scanSummary = '扫描启动失败';
      error = '扫描失败或权限被拒绝：$e';
      if (nativeRequested) {
        try {
          await client.stopScan().timeout(operationLimit);
          if (await client.isScanning().timeout(operationLimit)) {
            throw StateError('适配器仍在扫描');
          }
        } catch (cleanupError) {
          if (_closed || generation != _scanGeneration) return;
          scanPhase = BleScanPhase.unconfirmed;
          scanSummary = '启动失败后的停止尚未确认';
          error = '$error；停止未确认：$cleanupError';
        }
      }
      if (_closed || generation != _scanGeneration) return;
      _log(error!);
    } finally {
      _scanStartInFlight = false;
      _notify();
    }
  }

  Future<void> _releaseLateScan(int generation) async {
    // A newer scan attempt owns the adapter now.
    if (!_closed &&
        generation != _scanGeneration &&
        (scanPhase == BleScanPhase.running ||
            scanPhase == BleScanPhase.starting)) {
      return;
    }
    final cleanupGeneration = _scanGeneration;
    try {
      await client.stopScan().timeout(operationLimit);
      if (await client.isScanning().timeout(operationLimit)) {
        throw StateError('适配器仍在扫描');
      }
    } catch (e) {
      if (_closed || cleanupGeneration != _scanGeneration) return;
      scanPhase = BleScanPhase.unconfirmed;
      scanSummary = '迟到扫描的停止尚未确认';
      error = '停止扫描未确认：$e';
      _log(error!);
    }
  }

  Future<void> stopScan({String reason = '手动停止'}) async {
    if (scanPhase == BleScanPhase.idle || scanPhase == BleScanPhase.stopping) {
      return;
    }
    final generation = ++_scanGeneration;
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanDeadline = null;
    scanPhase = BleScanPhase.stopping;
    scanSummary = '正在确认扫描停止';
    _notify();
    try {
      await client.stopScan().timeout(operationLimit);
      if (await client.isScanning().timeout(operationLimit)) {
        throw StateError('适配器仍在扫描');
      }
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.idle;
      if (error?.startsWith('停止扫描未确认') ?? false) error = null;
      scanSummary = '$reason · 本轮 ${currentRoundIds.length} 台';
      _log(
        currentRoundIds.isEmpty
            ? '$reason：未发现 BLE 外设'
            : '$reason：本轮 ${currentRoundIds.length} 台设备',
      );
    } catch (e) {
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.unconfirmed;
      scanSummary = '停止尚未确认，可再次停止';
      error = '停止扫描未确认：$e';
      _log(error!);
    }
  }

  void clearScanHistory() {
    if (scanning || _scanStartInFlight) return;
    devices.removeWhere((id, _) => id != connectedId);
    lastSeen.clear();
    discoveryOrder.clear();
    currentRoundIds.clear();
    _notify();
  }
}
