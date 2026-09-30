import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/pages/list_page.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/pages/popup_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final captureDirectory = kIsWeb
      ? null
      : Platform.environment['FORGE_CAPTURE_DIR'];
  setUpAll(() async {
    if (captureDirectory == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
    final loader = FontLoader('ScreenshotFont');
    loader.addFont(
      Future.value(ByteData.sublistView(await font.readAsBytes())),
    );
    await loader.load();
    final codeFont = FontLoader('monospace');
    codeFont.addFont(
      Future.value(ByteData.sublistView(await font.readAsBytes())),
    );
    await codeFont.load();
  });

  for (final width in [320.0, 1100.0]) {
    for (final table in [false, true]) {
      testWidgets(
        '${table ? 'table' : 'popup'} teaching page fits ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: captureDirectory == null
                      ? null
                      : 'ScreenshotFont',
                ),
                home: table ? const ListPage() : const PopupPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(table ? '二维滚动表格演示' : '弹窗组件'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (captureDirectory != null) {
            await _capture(
              tester,
              key,
              '$captureDirectory/${table ? 'table' : 'popup'}-${width.toInt()}.png',
            );
          }
          if (table) {
            await tester.tap(find.text('学习任务 1'));
            await tester.pumpAndSettle();
            expect(find.text('编辑单元格'), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (captureDirectory != null) {
              await _capture(
                tester,
                key,
                '$captureDirectory/editor-${width.toInt()}.png',
              );
            }
            await tester.tap(find.text('取消'));
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String file) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File(file);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
