import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import 'desktop_window_host.dart';
import 'forge_nav_tile.dart';
import 'forge_selectable_list.dart';
import 'module_quick_open.dart';
import 'theme/forge_glass.dart';
import 'theme/theme_mode_button.dart';
import 'workbench_history.dart';
import 'navigation_session.dart';

class DesktopWorkbenchShell extends StatefulWidget {
  const DesktopWorkbenchShell({
    super.key,
    required this.modules,
    required this.location,
    required this.platform,
    required this.child,
    this.focusedCategory,
  });
  final List<ModuleEntry> modules;
  final String location;
  final AppPlatformSnapshot platform;
  final Widget child;
  final ModuleCategory? focusedCategory;

  @override
  State<DesktopWorkbenchShell> createState() => _DesktopWorkbenchShellState();
}

class _DesktopWorkbenchShellState extends State<DesktopWorkbenchShell> {
  bool _sidebarVisible = true;
  double _sidebarWidth = 240;
  bool _goingBack = false;
  late final List<String> _locations = [widget.location];
  ModuleCategory? _expandedCategory;
  DesktopWindowController? _window;

  ModuleEntry? get _currentModule {
    for (final module in widget.modules) {
      if (widget.location == module.path ||
          widget.location.startsWith('${module.path}/')) {
        return module;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _expandedCategory = widget.focusedCategory ?? _currentModule?.category;
    _recordRecent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final window = DesktopWindowScope.maybeOf(context);
    if (_window == window) return;
    _window?.removeListener(_onWindowCommand);
    _window = window;
    _window?.addListener(_onWindowCommand);
  }

  @override
  void didUpdateWidget(DesktopWorkbenchShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      if (_goingBack) {
        _goingBack = false;
      } else {
        _locations.add(widget.location);
        if (_locations.length > 64) _locations.removeAt(0);
      }
      _expandedCategory = _currentModule?.category ?? _expandedCategory;
      _recordRecent();
    }
  }

  void _recordRecent() {
    final module = _currentModule;
    if (module == null || widget.focusedCategory != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WorkbenchHistoryScope.maybeOf(context)?.record(module.path);
    });
  }

  void _onWindowCommand() {
    switch (_window?.takeCommand()) {
      case 'toggleSidebar':
        setState(() => _sidebarVisible = !_sidebarVisible);
      case 'back':
        _back();
    }
  }

  void _back() {
    if (_locations.length < 2) return;
    _locations.removeLast();
    _goingBack = true;
    context.go(_locations.last);
    final session = NavigationSessionScope.maybeOf(context);
    if (session?.quickOpenOrigin == _locations.last) {
      session?.quickOpenOrigin = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  Future<void> _windowAction(String action) async {
    try {
      await _window?.perform(action);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('窗口操作失败：${error.message ?? action}')),
        );
      }
    }
  }

  List<Object> get _navigationEntries => [
    for (final category
        in widget.focusedCategory == null
            ? ModuleCategory.values
            : [widget.focusedCategory!]) ...[
      category,
      if (_expandedCategory == category)
        ...widget.modules.where((module) => module.category == category),
    ],
  ];

  int get _selectedEntryIndex {
    final entries = _navigationEntries;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (entry is ModuleEntry && entry == _currentModule) return index;
      if (entry is ModuleCategory &&
          widget.location == '/category/${entry.name}') {
        return index;
      }
    }
    return 0;
  }

  void _activateEntry(Object entry) {
    if (entry is ModuleCategory) {
      setState(() => _expandedCategory = entry);
      context.go(
        widget.focusedCategory == null ? '/category/${entry.name}' : '/',
      );
    } else if (entry is ModuleEntry) {
      context.go(entry.path);
    }
  }

  Color _contentSurfaceColor(BuildContext context) {
    final scope = ForgeSurfaceScope.maybeOf(context);
    if (scope?.teaching == true) return Theme.of(context).colorScheme.surface;
    if (scope?.nativeMaterial != true) return Colors.transparent;
    // Native-material hierarchy: chrome tints lightest, content grounds the
    // page, cards sit near-solid on top — opacity is the elevation.
    return Theme.of(context).colorScheme.surface.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.5,
    );
  }

  String get _title {
    if (_currentModule case final module?) return module.title;
    if (widget.location == '/about') return '关于 Flutter Forge';
    if (widget.focusedCategory case final category?) return category.label;
    for (final category in ModuleCategory.values) {
      if (widget.location == '/category/${category.name}') {
        return category.label;
      }
    }
    return '学习工作台';
  }

  @override
  void dispose() {
    _window?.removeListener(_onWindowCommand);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _navigationEntries;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f11): () =>
            unawaited(_windowAction('toggleFullscreen')),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _search,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _search,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _search,
        const SingleActivator(LogicalKeyboardKey.bracketLeft, alt: true): _back,
        const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
            _back,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: const ValueKey('desktop-workbench-shell'),
          backgroundColor: Colors.transparent,
          body: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
              children: [
                _titlebar(),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      if (_sidebarVisible) ...[
                        SizedBox(
                          key: const ValueKey('workbench-sidebar'),
                          width: _sidebarWidth,
                          child: ForgeShellSurface(
                            edgeHighlight: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.focusedCategory == null)
                                  ForgeNavTile(
                                    label: '学习工作台',
                                    icon: Icons.space_dashboard_outlined,
                                    indent: 8,
                                    selected: widget.location == '/',
                                    onTap: () => context.go('/'),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    '学习模块',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  child: ForgeSelectableList(
                                    key: const ValueKey(
                                      'workbench-module-tree',
                                    ),
                                    itemCount: entries.length,
                                    selectedIndex: _selectedEntryIndex,
                                    onActivate: _activateEntry,
                                    itemBuilder: (context, index, active) {
                                      final entry = entries[index];
                                      if (entry is ModuleCategory) {
                                        return ForgeNavTile(
                                          key: ValueKey(
                                            'sidebar-category:${entry.name}',
                                          ),
                                          label: entry.label,
                                          icon: entry.icon,
                                          indent: 8,
                                          keyboardActive: active,
                                          selected:
                                              widget.location ==
                                                  '/category/${entry.name}' ||
                                              (widget.focusedCategory ==
                                                      entry &&
                                                  widget.location == '/'),
                                          trailing: IconButton(
                                            tooltip: _expandedCategory == entry
                                                ? '收起分类'
                                                : '展开分类',
                                            onPressed: () => setState(() {
                                              _expandedCategory =
                                                  _expandedCategory == entry
                                                  ? null
                                                  : entry;
                                            }),
                                            icon: Icon(
                                              _expandedCategory == entry
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              size: 18,
                                            ),
                                          ),
                                          onTap: () => _activateEntry(entry),
                                        );
                                      }
                                      final module = entry as ModuleEntry;
                                      return ForgeNavTile(
                                        key: ValueKey(
                                          'sidebar-module:${module.path}',
                                        ),
                                        label: module.title,
                                        indent: 20,
                                        keyboardActive: active,
                                        selected: module == _currentModule,
                                        trailing:
                                            module.isSupportedOn(
                                              widget.platform,
                                            )
                                            ? null
                                            : const Tooltip(
                                                message: '当前平台不可用',
                                                child: Icon(
                                                  Icons.info_outline,
                                                  size: 14,
                                                ),
                                              ),
                                        onTap: () => context.go(module.path),
                                      );
                                    },
                                  ),
                                ),
                                if (widget.focusedCategory == null)
                                  ForgeNavTile(
                                    key: const ValueKey('sidebar-about'),
                                    label: '关于 Flutter Forge',
                                    icon: Icons.info_outline,
                                    indent: 8,
                                    selected: widget.location == '/about',
                                    onTap: () => context.go('/about'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) => setState(() {
                              _sidebarWidth = (_sidebarWidth + details.delta.dx)
                                  .clamp(200, 320);
                            }),
                            child: const SizedBox(
                              width: 5,
                              child: VerticalDivider(width: 1),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: ColoredBox(
                          key: const ValueKey('workbench-content-surface'),
                          color: _contentSurfaceColor(context),
                          child: Semantics(
                            container: true,
                            explicitChildNodes: true,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _search() => unawaited(showModuleQuickOpen(context, widget.modules));

  Widget _dragRegion(Widget child, {Key? key}) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => unawaited(_windowAction('drag')),
    onDoubleTap: () => unawaited(_windowAction('captionDoubleClick')),
    child: child,
  );

  Widget _titlebar() {
    final window = DesktopWindowScope.maybeOf(context);
    return ForgeShellSurface(
      titlebar: true,
      edgeHighlight: true,
      child: SizedBox(
        key: const ValueKey('immersive-titlebar'),
        height: 48,
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              SizedBox(
                key: const ValueKey('native-leading-controls'),
                width:
                    window?.leadingInset ??
                    (widget.platform.platform == AppTargetPlatform.macOS
                        ? 80
                        : 6),
              ),
              IconButton(
                tooltip: _sidebarVisible ? '收起侧栏' : '展开侧栏',
                onPressed: () =>
                    setState(() => _sidebarVisible = !_sidebarVisible),
                icon: const Icon(Icons.vertical_split_outlined, size: 18),
              ),
              IconButton(
                key: const ValueKey('workbench-back'),
                tooltip: '返回上一页',
                onPressed: _locations.length > 1 ? _back : null,
                icon: const Icon(Icons.arrow_back, size: 18),
              ),
              IconButton(
                key: const ValueKey('workbench-home-button'),
                tooltip: widget.focusedCategory == null ? '返回工作台' : '返回分类主页',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined, size: 18),
              ),
              Expanded(
                child: _dragRegion(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  key: const ValueKey('titlebar-drag-area'),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth >= 1000 ? 280 : 170,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    key: const ValueKey('workbench-search'),
                    onPressed: _search,
                    icon: const Icon(Icons.search, size: 17),
                    label: const Text('快速打开'),
                  ),
                ),
              ),
              _dragRegion(const SizedBox(width: 24, height: 48)),
              const ThemeModeButton(),
              _captionButton(
                'toggleFullscreen',
                window?.fullscreen == true ? '退出全屏' : '进入全屏',
                window?.fullscreen == true
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                window,
              ),
              SizedBox(
                key: const ValueKey('native-trailing-controls'),
                width:
                    window?.trailingInset ??
                    (widget.platform.platform == AppTargetPlatform.windows
                        ? 138
                        : 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _captionButton(
    String method,
    String label,
    IconData icon,
    DesktopWindowController? window,
  ) => SizedBox(
    width: 44,
    height: 48,
    child: Semantics(
      label: label,
      button: true,
      enabled: window?.ready == true,
      onTap: window?.ready == true
          ? () => unawaited(_windowAction(method))
          : null,
      excludeSemantics: true,
      child: IconButton(
        key: ValueKey('window:$method'),
        tooltip: label,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          foregroundColor: window?.active == false
              ? Theme.of(context).disabledColor
              : null,
          hoverColor: method == 'close'
              ? Theme.of(context).colorScheme.errorContainer
              : null,
        ),
        onPressed: window?.ready == true
            ? () => unawaited(_windowAction(method))
            : null,
        icon: Icon(icon, size: 17),
      ),
    ),
  );
}
