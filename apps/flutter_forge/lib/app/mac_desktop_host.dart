import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_entry.dart';
import 'module_search.dart';

class MacDesktopHost extends StatefulWidget {
  const MacDesktopHost({
    super.key,
    required this.router,
    required this.modules,
    required this.themeMode,
    required this.child,
    this.hasSidebar = true,
    this.title = 'Flutter Forge',
  });

  static const channel = MethodChannel('flutter_forge/desktop_host');
  final GoRouter router;
  final List<ModuleEntry> modules;
  final ThemeMode themeMode;
  final Widget child;
  final bool hasSidebar;
  final String title;

  @override
  State<MacDesktopHost> createState() => _MacDesktopHostState();
}

class _MacDesktopHostState extends State<MacDesktopHost> {
  final _sidebar = MacDesktopSidebarController();
  bool _searchOpen = false;
  late final _enabled =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_enabled) {
      MacDesktopHost.channel.setMethodCallHandler(_handleCommand);
      unawaited(_syncAppearance());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_ensureMenus());
      });
    }
  }

  @override
  void didUpdateWidget(MacDesktopHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled &&
        (widget.themeMode != oldWidget.themeMode ||
            widget.title != oldWidget.title ||
            widget.hasSidebar != oldWidget.hasSidebar)) {
      unawaited(_syncAppearance());
    }
  }

  Future<void> _syncAppearance() async {
    try {
      await MacDesktopHost.channel.invokeMethod<void>(
        'setAppearance',
        widget.themeMode.name,
      );
      await MacDesktopHost.channel.invokeMethod<void>(
        'setSidebarAvailable',
        widget.hasSidebar,
      );
      await MacDesktopHost.channel.invokeMethod<void>('setTitle', widget.title);
    } on MissingPluginException {
      // Widget tests and older hosts can still render the content shell.
    }
  }

  Future<void> _ensureMenus() async {
    try {
      await MacDesktopHost.channel.invokeMethod<void>('ensureMenus');
    } on MissingPluginException {
      // Older native hosts can continue using their standard menus.
    }
  }

  Future<void> _handleCommand(MethodCall call) async {
    if (!mounted) return;
    switch (call.method) {
      case 'toggleSidebar':
        _sidebar.toggle();
      case 'home':
        widget.router.go('/');
      case 'back':
        if (widget.router.canPop()) widget.router.pop();
      case 'search':
        final context = widget
            .router
            .routerDelegate
            .navigatorKey
            .currentState
            ?.overlay
            ?.context;
        if (context == null || _searchOpen) return;
        _searchOpen = true;
        try {
          await showSearch<void>(
            context: context,
            delegate: ModuleSearchDelegate(widget.modules),
          );
        } finally {
          _searchOpen = false;
        }
      default:
        throw MissingPluginException('Unknown desktop command: ${call.method}');
    }
  }

  @override
  void dispose() {
    if (_enabled) MacDesktopHost.channel.setMethodCallHandler(null);
    _sidebar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _enabled
      ? MacDesktopScope(sidebar: _sidebar, child: widget.child)
      : widget.child;
}

class MacDesktopSidebarController extends ChangeNotifier {
  void toggle() => notifyListeners();
}

class MacDesktopScope extends InheritedWidget {
  const MacDesktopScope({
    super.key,
    required this.sidebar,
    required super.child,
  });

  final ChangeNotifier sidebar;

  static ChangeNotifier? sidebarOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MacDesktopScope>()?.sidebar;

  @override
  bool updateShouldNotify(MacDesktopScope oldWidget) =>
      sidebar != oldWidget.sidebar;
}
