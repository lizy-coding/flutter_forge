import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const PopupListInteractionEntry(), isA<Widget>());
  });
}
