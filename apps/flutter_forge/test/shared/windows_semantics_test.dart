import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_forge_app/modules/basic/constraint_layout/module_entry.dart';
import 'package:flutter_forge_app/modules/platform/online_video_player/state/video_player_adapter.dart';
import 'package:flutter_forge_app/modules/platform/online_video_player/widgets/video_player_controls.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_workbench_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/shared/learning/learning_slider.dart';

class _RecordingBinding extends AutomatedTestWidgetsFlutterBinding {
  final nodes = <int, List<int>>{};
  final orphans = <int>[];
  final missingChildren = <int>[];

  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() =>
      _RecordingBuilder(this);
}

// Replay the engine's child references across incremental semantics updates.
// A node serialized this frame must be reachable from the root afterwards.
class _RecordingBuilder implements ui.SemanticsUpdateBuilder {
  _RecordingBuilder(this.binding);
  final _RecordingBinding binding;
  final updated = <int>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateNode) {
      final args = invocation.namedArguments;
      final id = args[#id] as int;
      binding.nodes[id] = List<int>.from(
        args[#childrenInTraversalOrder] as Iterable,
      );
      updated.add(id);
      return null;
    }
    if (invocation.memberName == #updateCustomAction) return null;
    return super.noSuchMethod(invocation);
  }

  @override
  ui.SemanticsUpdate build() {
    final reachable = <int>{};
    void visit(int id) {
      if (!reachable.add(id)) return;
      if (!binding.nodes.containsKey(id)) binding.missingChildren.add(id);
      for (final child in binding.nodes[id] ?? <int>[]) {
        visit(child);
      }
    }

    visit(0);
    binding.orphans.addAll(updated.where((id) => !reachable.contains(id)));
    binding.nodes.removeWhere((id, _) => !reachable.contains(id));
    return ui.SemanticsUpdateBuilder().build();
  }
}

void main() {
  final binding = _RecordingBinding();
  testWidgets('slider in a pushed route sends no orphan semantics nodes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Home')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: ListView(
            children: [LearningSlider(value: 0.5, onChanged: (_) {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(find.byType(LearningSlider), findsOneWidget);
    expect(binding.orphans, isEmpty);
    expect(binding.missingChildren, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  for (final entry in ['constraints', 'video', 'genui']) {
    testWidgets('$entry route keeps every semantics update reachable', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final navigator = GlobalKey<NavigatorState>();
      final video = VideoPlayerPluginAdapter(startAutomatically: false);
      final session = GenuiSession();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Home')),
        ),
      );
      binding.orphans.clear();
      binding.missingChildren.clear();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => switch (entry) {
            'constraints' => const ConstraintLayoutEntry(),
            'video' => Scaffold(body: VideoPlayerControls(adapter: video)),
            _ => Scaffold(body: GenuiWorkbenchPage(session: session)),
          },
        ),
      );
      await tester.pumpAndSettle();
      if (entry == 'genui') {
        await tester.runAsync(() => session.submit('为什么设置宽度却没有生效？'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('解释当前结果'));
        await tester.pumpAndSettle();
        expect(session.hasSurface, isTrue);
      }
      final emittedOrphans = List<int>.of(binding.orphans);
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
      session.dispose();
      video.dispose();
      expect(emittedOrphans, isEmpty);
      expect(binding.missingChildren, isEmpty);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets(
    'Windows slider preserves keyboard, pointer and semantics actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 0.5;
      final gestures = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LearningSlider(
                value: value,
                divisions: 10,
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()} units',
                onChanged: (next) => setState(() => value = next),
                onChangeStart: (_) => gestures.add('start'),
                onChangeEnd: (_) => gestures.add('end'),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, closeTo(0.6, 0.001));
      expect(gestures, ['start', 'end']);
      final node = tester.getSemantics(find.byType(LearningSlider));
      expect(node.getSemanticsData().value, '60 units');
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.increase),
        isTrue,
      );
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          viewId: tester.view.viewId,
          nodeId: node.id,
          type: ui.SemanticsAction.increase,
        ),
      );
      await tester.pump();
      expect(value, closeTo(0.7, 0.001));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 1);
      final sliderRect = tester.getRect(find.byType(CupertinoSlider));
      await tester.dragFrom(
        Offset(sliderRect.right - 24, sliderRect.center.dy),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(value, lessThan(1));
      await tester.tapAt(
        Offset(sliderRect.left + sliderRect.width / 4, sliderRect.center.dy),
      );
      await tester.pumpAndSettle();
      expect(value, closeTo(0.3, 0.001));
      semantics.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets('disabled and fixed-range sliders expose no adjustable actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const LearningSlider(
                key: ValueKey('disabled'),
                value: 0.5,
                onChanged: null,
              ),
              LearningSlider(
                key: const ValueKey('fixed'),
                min: 1,
                max: 1,
                value: 1,
                onChanged: (_) => changes++,
              ),
            ],
          ),
        ),
      ),
    );
    for (final key in ['disabled', 'fixed']) {
      final finder = find.byKey(ValueKey(key));
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.hasAction(ui.SemanticsAction.increase), isFalse);
      expect(data.hasAction(ui.SemanticsAction.decrease), isFalse);
      await tester.tap(finder);
    }
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
