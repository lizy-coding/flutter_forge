import 'package:flutter/widgets.dart';

class FocusWindowNavigation extends InheritedWidget {
  const FocusWindowNavigation({
    super.key,
    required this.openInMain,
    required super.child,
  });

  final Future<void> Function(String) openInMain;

  static FocusWindowNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FocusWindowNavigation>();

  @override
  bool updateShouldNotify(FocusWindowNavigation oldWidget) =>
      openInMain != oldWidget.openInMain;
}
