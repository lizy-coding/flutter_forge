import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/popup/popup_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'leaving during a route sequence cancels pending opens and preserves destination',
    (tester) async {
      final showOwner = ValueNotifier(true);
      addTearDown(showOwner.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showOwner,
            builder: (_, show, __) => show
                ? const _Owner()
                : const Scaffold(body: Text('destination')),
          ),
        ),
      );
      final initialBarriers = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.text('routes'));
      await tester.pump();
      expect(find.text('popup A'), findsOneWidget);
      showOwner.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('destination'), findsOneWidget);
      expect(find.textContaining('popup '), findsNothing);
      expect(find.byType(ModalBarrier), findsNWidgets(initialBarriers));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'overlay close cancels opening and removes the barrier atomically',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _Owner()));
      final initialBarriers = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.text('overlays'));
      await tester.pump();
      final state = tester.state<_OwnerState>(find.byType(_Owner));
      unawaited(
        state.scope.sequence('overlay', [
          'A',
          'B',
          'C',
        ], state.scope.closeOverlay),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('overlay '), findsNothing);
      expect(find.byType(ModalBarrier), findsNWidgets(initialBarriers));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving during overlay opening releases entries and completes delays',
    (tester) async {
      final showOwner = ValueNotifier(true);
      addTearDown(showOwner.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showOwner,
            builder: (_, show, __) => show
                ? const _Owner()
                : const Scaffold(body: Text('destination')),
          ),
        ),
      );
      final initialBarriers = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.text('overlays'));
      await tester.pump();
      showOwner.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('overlay '), findsNothing);
      expect(find.byType(ModalBarrier), findsNWidgets(initialBarriers));
      expect(tester.takeException(), isNull);
    },
  );
}

class _Owner extends StatefulWidget {
  const _Owner();
  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  final scope = PopupScope();

  void openRoutes() {
    final navigator = Navigator.of(context);
    unawaited(
      scope.sequence('dialog', ['A', 'B', 'C'], (id) {
        unawaited(
          scope.push<void>(
            navigator,
            DialogRoute<void>(
              context: context,
              builder: (_) => AlertDialog(content: Text('popup $id')),
            ),
            id: id,
          ),
        );
      }),
    );
  }

  void openOverlays() {
    final overlay = Overlay.of(context);
    unawaited(
      scope.sequence('overlay', ['A', 'B', 'C'], (id) {
        scope.insertOverlay(id, overlay, [
          OverlayEntry(builder: (_) => const ModalBarrier(dismissible: false)),
          OverlayEntry(
            builder: (_) => Center(child: Material(child: Text('overlay $id'))),
          ),
        ]);
      }),
    );
  }

  @override
  void dispose() {
    scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(onPressed: openRoutes, child: const Text('routes')),
        TextButton(onPressed: openOverlays, child: const Text('overlays')),
      ],
    ),
  );
}
