part of 'ble_session.dart';

/// GATT access on the established link: characteristic reads and
/// notify/indicate subscriptions. Every step re-checks the link generation
/// so values from a torn-down connection never land in the session.
extension BleGattControl on BleSession {
  Future<void> read(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (!gattReady ||
        id == null ||
        !characteristic.properties.contains(CharacteristicProperty.read)) {
      return;
    }
    final generation = _generation;
    final key = '${service.uuid}/${characteristic.uuid}';
    if (!pendingCharacteristics.add(key)) return;
    _notify();
    try {
      final value = await client
          .read(id, service.uuid, characteristic.uuid)
          .timeout(operationLimit);
      if (!_currentLink(generation) || connectedId != id || !gattReady) return;
      values[key] = value;
      _log('读取 ${characteristic.uuid}：${BleSession.hex(value)}');
    } catch (e) {
      if (!_currentLink(generation)) return;
      error = '读取失败：$e';
      _log(error!);
    } finally {
      if (_currentLink(generation)) {
        pendingCharacteristics.remove(key);
        _notify();
      }
    }
  }

  Future<void> toggleSubscription(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (!gattReady || id == null) return;
    final key = '${service.uuid}/${characteristic.uuid}';
    final generation = _generation;
    final indicate = characteristic.properties.contains(
      CharacteristicProperty.indicate,
    );
    if (!indicate &&
        !characteristic.properties.contains(CharacteristicProperty.notify)) {
      return;
    }
    if (!pendingCharacteristics.add(key)) return;
    _notify();
    try {
      if (subscriptions.contains(key)) {
        await client
            .unsubscribe(id, service.uuid, characteristic.uuid)
            .timeout(operationLimit);
        if (!_currentLink(generation)) return;
        await _valueSubscriptions.remove(key)?.cancel();
        subscriptions.remove(key);
        _log('停止订阅 ${characteristic.uuid}');
      } else {
        final listener = client.values(id, characteristic.uuid).listen((data) {
          if (!_currentLink(generation) || connectedId != id) return;
          values[key] = data;
          _log('收到 ${characteristic.uuid}：${BleSession.hex(data)}');
        });
        _valueSubscriptions[key] = listener;
        await client
            .subscribe(
              id,
              service.uuid,
              characteristic.uuid,
              indicate: indicate,
            )
            .timeout(operationLimit);
        if (!_currentLink(generation)) {
          await listener.cancel();
          return;
        }
        subscriptions.add(key);
        _log('订阅 ${characteristic.uuid}');
      }
    } catch (e) {
      if (!_currentLink(generation)) return;
      await _valueSubscriptions.remove(key)?.cancel();
      error = '订阅操作失败：$e';
      _log(error!);
    } finally {
      if (_currentLink(generation)) {
        pendingCharacteristics.remove(key);
        _notify();
      }
    }
  }
}
