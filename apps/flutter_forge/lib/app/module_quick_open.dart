import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_entry.dart';
import 'theme/forge_glass.dart';
import 'workbench_history.dart';
import 'module_search.dart';
import 'navigation_session.dart';

Future<void> showModuleQuickOpen(
  BuildContext context,
  List<ModuleEntry> modules,
) async {
  final session = NavigationSessionScope.maybeOf(context);
  if (session?.quickOpenVisible == true) return;
  session?.quickOpenVisible = true;
  ModuleEntry? selected;
  final origin = GoRouter.of(context).routeInformationProvider.value.uri.path;
  try {
    final recent = WorkbenchHistoryScope.maybeOf(context)?.recent ?? const [];
    selected = await showDialog<ModuleEntry>(
      context: context,
      barrierLabel: '关闭快速打开',
      builder: (_) => _QuickOpenDialog(modules: modules, recent: recent),
    );
  } finally {
    session?.quickOpenVisible = false;
  }
  if (selected != null && context.mounted) {
    session?.quickOpenOrigin = selected.path == origin ? null : origin;
    context.go(selected.path);
  }
}

class _QuickOpenDialog extends StatefulWidget {
  const _QuickOpenDialog({required this.modules, required this.recent});
  final List<ModuleEntry> modules;
  final List<String> recent;

  @override
  State<_QuickOpenDialog> createState() => _QuickOpenDialogState();
}

class _QuickOpenDialogState extends State<_QuickOpenDialog> {
  final _scroll = ScrollController();
  late final _focus = FocusNode(onKeyEvent: _handleKey);
  String _query = '';
  TextEditingController? _queryController;
  int _selected = 0;

  List<ModuleEntry> get _matches {
    final query = _query.trim().toLowerCase();
    final matches = widget.modules.where((module) {
      return query.isEmpty || matchesModule(module, query);
    }).toList();
    if (query.isEmpty) {
      int order(ModuleEntry m) {
        final index = widget.recent.indexOf(m.path);
        return index < 0 ? widget.recent.length : index;
      }

      final sourceOrder = {
        for (var i = 0; i < widget.modules.length; i++)
          widget.modules[i].path: i,
      };
      matches.sort((a, b) {
        final comparison = order(a).compareTo(order(b));
        return comparison != 0
            ? comparison
            : sourceOrder[a.path]!.compareTo(sourceOrder[b.path]!);
      });
    }
    return matches;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final matches = _matches;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (matches.isNotEmpty) Navigator.of(context).pop(matches[_selected]);
      return KeyEventResult.handled;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowUp
        ? -1
        : 0;
    if (delta == 0 || matches.isEmpty) return KeyEventResult.ignored;
    setState(
      () => _selected = (_selected + delta).clamp(0, matches.length - 1),
    );
    if (_scroll.hasClients) {
      final offset = (_selected * 64.0).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.jumpTo(offset);
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _queryController?.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = NavigationSessionScope.maybeOf(context);
    if (_queryController == null) {
      _query = session?.quickOpenQuery ?? '';
      _queryController = TextEditingController(text: _query);
    }
    final matches = _matches;
    final height = math.min(480.0, MediaQuery.sizeOf(context).height - 96);
    return Dialog(
      key: const ValueKey('module-quick-open'),
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: height),
        child: ForgeShellSurface(
          radius: 12,
          floating: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const ValueKey('quick-open-query'),
                  controller: _queryController,
                  autofocus: true,
                  focusNode: _focus,
                  decoration: InputDecoration(
                    hintText: '搜索模块、概念或分类',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      tooltip: '关闭快速打开',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                  onChanged: (value) => setState(() {
                    _query = value;
                    session?.quickOpenQuery = value;
                    _selected = 0;
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                  }),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('没有匹配模块，请尝试其他关键词'))
                    : ListView.builder(
                        controller: _scroll,
                        itemExtent: 64,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final module = matches[index];
                          return ListTile(
                            key: ValueKey('quick-open:${module.path}'),
                            selected: index == _selected,
                            selectedTileColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            title: Text(
                              module.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(module.category.label),
                            trailing: widget.recent.contains(module.path)
                                ? const Tooltip(
                                    message: '最近访问',
                                    child: Icon(Icons.history, size: 16),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(module),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  '↑ ↓ 选择    Enter 打开    Esc 返回',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
