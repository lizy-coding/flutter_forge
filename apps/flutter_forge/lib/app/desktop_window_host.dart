import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_entry.dart';
import 'module_quick_open.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_selection.dart';
import 'theme/forge_glass.dart';

bool isTeachingLocation(String location, List<ModuleEntry> modules) =>
    modules.any(
      (module) =>
          location == module.path || location.startsWith('${module.path}/'),
    );

class DesktopWindowController extends ChangeNotifier {
  bool ready = false;
  bool active = true;
  bool fullscreen = false;
  double? leadingInset;
  double? trailingInset;
  bool materialActive = false;
  bool transparencyAllowed = true;
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
    materialActive = state['materialActive'] as bool? ?? materialActive;
    transparencyAllowed =
        state['transparencyAllowed'] as bool? ?? transparencyAllowed;
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
    this.materialEnabled = false,
  });

  static const channel = MethodChannel('flutter_forge/desktop_host');
  final GoRouter router;
  final List<ModuleEntry> modules;
  final ThemeMode themeMode;
  final Widget child;
  final bool mainWindow;
  final AppPlatformSnapshot platform;
  final String title;
  final bool materialEnabled;

  @override
  State<DesktopWindowHost> createState() => _DesktopWindowHostState();
}

class _DesktopWindowHostState extends State<DesktopWindowHost> {
  final _controller = DesktopWindowController();
  late final _enabled = widget.platform.hostFamily == AppHostFamily.desktop;
  String? _lastConfiguration;
  Map<String, Object>? _desiredConfiguration;
  Future<void>? _configurationTask;
  bool _configurationFailed = false;
  Timer? _configurationTimer;
  Completer<Map<dynamic, dynamic>?>? _configurationReply;
  Timer? _retryTimer;
  Completer<void>? _retryWaiter;

  void _routeChanged() {
    if (!mounted) return;
    setState(() {});
    unawaited(_configure());
  }

  @override
  void initState() {
    super.initState();
    widget.router.routeInformationProvider.addListener(_routeChanged);
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
    if (widget.router != oldWidget.router) {
      oldWidget.router.routeInformationProvider.removeListener(_routeChanged);
      widget.router.routeInformationProvider.addListener(_routeChanged);
      _lastConfiguration = null;
    }
    if (_enabled &&
        (widget.themeMode != oldWidget.themeMode ||
            widget.title != oldWidget.title ||
            widget.materialEnabled != oldWidget.materialEnabled ||
            widget.router != oldWidget.router)) {
      unawaited(_configure());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_configure());
      });
    }
  }

  Future<void> _configure() async {
    if (!_enabled || !mounted) return;
    final teaching = isTeachingLocation(
      widget.router.routeInformationProvider.value.uri.path,
      widget.modules,
    );
    final highContrast = MediaQuery.highContrastOf(context);
    final arguments = <String, Object>{
      'mainWindow': widget.mainWindow,
      'title': widget.title,
      'themeMode': widget.themeMode.name,
      'materialEnabled': widget.materialEnabled && !highContrast,
      'teaching': teaching,
    };
    final signature = arguments.toString();
    final changed = _desiredConfiguration.toString() != signature;
    _desiredConfiguration = arguments;
    if (_lastConfiguration == signature) return;
    if (changed) _cancelRetryWait();
    _configurationTask ??= _sendConfigurations().whenComplete(() {
      _configurationTask = null;
    });
    await _configurationTask;
  }

  Future<void> _sendConfigurations() async {
    while (mounted) {
      final arguments = _desiredConfiguration!;
      final signature = arguments.toString();
      if (_lastConfiguration == signature) return;
      for (var attempt = 0; attempt < 3 && mounted; attempt++) {
        if (_desiredConfiguration.toString() != signature) break;
        try {
          // A failed request may have partially changed native state. Do not
          // reuse an earlier success when the user switches back to it.
          _lastConfiguration = null;
          final state = await _invokeConfiguration(arguments);
          if (!mounted) return;
          if (_desiredConfiguration.toString() != signature) {
            _lastConfiguration = null;
            break;
          }
          if (state == null) throw StateError('Desktop host returned no state');
          setState(() {
            _controller.update(state);
            _lastConfiguration = signature;
            _configurationFailed = false;
          });
          break;
        } catch (error) {
          if (!mounted) return;
          if (_desiredConfiguration.toString() != signature) {
            _lastConfiguration = null;
            break;
          }
          debugPrint(
            'Desktop window configuration attempt ${attempt + 1} failed: $error',
          );
          if (attempt == 2) {
            setState(() => _configurationFailed = true);
            return;
          }
          await _waitForRetry();
        }
      }
    }
  }

  Future<Map<dynamic, dynamic>?> _invokeConfiguration(
    Map<String, Object> arguments,
  ) {
    final reply = Completer<Map<dynamic, dynamic>?>();
    _configurationReply = reply;
    final timer = Timer(const Duration(seconds: 2), () {
      reply.completeError(TimeoutException('Desktop host configure timed out'));
    });
    _configurationTimer = timer;
    unawaited(
      DesktopWindowHost.channel
          .invokeMapMethod('configure', arguments)
          .then(
            (state) {
              if (!reply.isCompleted) reply.complete(state);
            },
            onError: (Object error, StackTrace stack) {
              if (!reply.isCompleted) reply.completeError(error, stack);
            },
          ),
    );
    return reply.future.whenComplete(() {
      timer.cancel();
      if (identical(_configurationReply, reply)) _configurationReply = null;
    });
  }

  Future<void> _waitForRetry() {
    final waiter = Completer<void>();
    _retryWaiter = waiter;
    _retryTimer = Timer(const Duration(milliseconds: 200), _cancelRetryWait);
    return waiter.future;
  }

  void _cancelRetryWait() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryWaiter?.complete();
    _retryWaiter = null;
  }

  Future<void> _handleCommand(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'windowState') {
      setState(
        () => _controller.update(call.arguments as Map<dynamic, dynamic>?),
      );
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
    _cancelRetryWait();
    _configurationTimer?.cancel();
    if (_configurationReply?.isCompleted == false) {
      _configurationReply?.complete();
    }
    widget.router.routeInformationProvider.removeListener(_routeChanged);
    if (_enabled) DesktopWindowHost.channel.setMethodCallHandler(null);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teaching = isTeachingLocation(
      widget.router.routeInformationProvider.value.uri.path,
      widget.modules,
    );
    final native =
        _enabled &&
        widget.materialEnabled &&
        _controller.materialActive &&
        _controller.transparencyAllowed &&
        !MediaQuery.highContrastOf(context);
    final theme = Theme.of(context);
    final solid = teaching || (_enabled && !native);
    return DesktopWindowScope(
      controller: _controller,
      child: ForgeSurfaceScope(
        nativeMaterial: native,
        teaching: teaching,
        child: Theme(
          data: solid
              ? (theme.brightness == Brightness.dark
                    ? AppTheme.dark(AppThemePalette.graphiteForge)
                    : AppTheme.light(AppThemePalette.graphiteForge))
              : theme,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (_enabled && _configurationFailed)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Material(
                    elevation: 6,
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: Text('窗口配置失败，可重试恢复窗口控制。')),
                          TextButton(
                            key: const ValueKey('desktop-window-retry'),
                            onPressed: () {
                              setState(() => _configurationFailed = false);
                              unawaited(_configure());
                            },
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
