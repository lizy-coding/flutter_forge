import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_entry.dart';
import 'module_quick_open.dart';

class DesktopWindowController extends ChangeNotifier {
  bool ready = false;
  bool active = true;
  bool fullscreen = false;
  double? leadingInset;
  double? trailingInset;
  String? _command;
  bool _disposed = false;

  void dispatch(String command) {
    _command = command;
    notifyListeners();
  }

  String? takeCommand() {
    final command = _command;
    _command = null;
    return command;
  }

  void update(Map<dynamic, dynamic>? state) {
    if (_disposed || state == null) return;
    ready = true;
    active = state['active'] as bool? ?? active;
    fullscreen = state['fullscreen'] as bool? ?? fullscreen;
    leadingInset = (state['leadingInset'] as num?)?.toDouble() ?? leadingInset;
    trailingInset =
        (state['trailingInset'] as num?)?.toDouble() ?? trailingInset;
    notifyListeners();
  }

  Future<void> perform(String method) async {
    if (!ready) return;
    update(await DesktopWindowHost.channel.invokeMapMethod(method));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class DesktopWindowScope extends InheritedNotifier<DesktopWindowController> {
  const DesktopWindowScope({
    super.key,
    required DesktopWindowController controller,
    required super.child,
  }) : super(notifier: controller);

  static DesktopWindowController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesktopWindowScope>()
      ?.notifier;
}

class DesktopWindowHost extends StatefulWidget {
  const DesktopWindowHost({
    super.key,
    required this.router,
    required this.modules,
    required this.themeMode,
    required this.child,
    required this.platform,
    this.mainWindow = true,
    this.title = 'Flutter Forge',
  });

  static const channel = MethodChannel('flutter_forge/desktop_host');
  final GoRouter router;
  final List<ModuleEntry> modules;
  final ThemeMode themeMode;
  final Widget child;
  final bool mainWindow;
  final AppPlatformSnapshot platform;
  final String title;

  @override
  State<DesktopWindowHost> createState() => _DesktopWindowHostState();
}

class _DesktopWindowHostState extends State<DesktopWindowHost> {
  final _controller = DesktopWindowController();
  late final _enabled = widget.platform.hostFamily == AppHostFamily.desktop;

  @override
  void initState() {
    super.initState();
    if (_enabled) {
      DesktopWindowHost.channel.setMethodCallHandler(_handleCommand);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_configure());
      });
    }
  }

  @override
  void didUpdateWidget(DesktopWindowHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled &&
        (widget.themeMode != oldWidget.themeMode ||
            widget.title != oldWidget.title)) {
      unawaited(_configure());
    }
  }

  Future<void> _configure() async {
    try {
      final state = await DesktopWindowHost.channel
          .invokeMapMethod('configure', {
            'mainWindow': widget.mainWindow,
            'title': widget.title,
            'themeMode': widget.themeMode.name,
          });
      if (mounted) _controller.update(state);
    } on MissingPluginException {
      // Widget tests and non-desktop hosts have no window control surface.
    } on PlatformException catch (error) {
      debugPrint('Desktop window configuration failed: ${error.message}');
    }
  }

  Future<void> _handleCommand(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'windowState') {
      _controller.update(call.arguments as Map<dynamic, dynamic>?);
    } else if (call.method == 'home') {
      widget.router.go('/');
    } else if (call.method == 'search') {
      final context = widget
          .router
          .routerDelegate
          .navigatorKey
          .currentState
          ?.overlay
          ?.context;
      if (context != null) await showModuleQuickOpen(context, widget.modules);
    } else if (call.method == 'back' || call.method == 'toggleSidebar') {
      _controller.dispatch(call.method);
    } else {
      throw MissingPluginException('Unknown desktop command: ${call.method}');
    }
  }

  @override
  void dispose() {
    if (_enabled) DesktopWindowHost.channel.setMethodCallHandler(null);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      DesktopWindowScope(controller: _controller, child: widget.child);
}
