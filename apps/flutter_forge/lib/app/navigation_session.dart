import 'package:flutter/material.dart';

class NavigationSession {
  final pages = PageStorageBucket();
  String searchQuery = '';
  String quickOpenQuery = '';
  String? quickOpenOrigin;
  bool quickOpenVisible = false;
}

class NavigationSessionScope extends StatefulWidget {
  const NavigationSessionScope({super.key, required this.child});
  final Widget child;

  static NavigationSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SessionProvider>()?.session;

  @override
  State<NavigationSessionScope> createState() => _NavigationSessionScopeState();
}

class _NavigationSessionScopeState extends State<NavigationSessionScope> {
  final session = NavigationSession();

  @override
  Widget build(BuildContext context) =>
      _SessionProvider(session: session, child: widget.child);
}

class _SessionProvider extends InheritedWidget {
  const _SessionProvider({required this.session, required super.child});
  final NavigationSession session;

  @override
  bool updateShouldNotify(_SessionProvider oldWidget) => false;
}
