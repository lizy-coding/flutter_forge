import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/popup_table/scroll_table/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const ScrollTableEntry(), isA<Widget>());
  });
}
