import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/basic/debounce_throttle/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const DebounceThrottleEntry(), isA<Widget>());
  });
}
