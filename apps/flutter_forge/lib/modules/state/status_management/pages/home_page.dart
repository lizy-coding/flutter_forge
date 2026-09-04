import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

const String _statusManageBaseRoute = '/status-management';

class StateFlowHome extends StatelessWidget {
  const StateFlowHome({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = <_RouteCategory>[
      _RouteCategory(
        title: 'Provider',
        description: '基于 InheritedWidget + ChangeNotifier',
        badge: 'Widget 树驱动',
        icon: Icons.extension,
        routes: [
          _HomeCardData(
            title: '基础 / 粒度刷新',
            flow: '事件 → notifyListeners → 重建',
            icon: Icons.auto_fix_high,
            routeName: '/provider',
            chipLabel: 'ChangeNotifier',
          ),
          _HomeCardData(
            title: '状态提升',
            flow: '父级集中管理 → 子组件共享',
            icon: Icons.vertical_align_top,
            routeName: '/provider/lifting',
            chipLabel: 'props 上提',
          ),
          _HomeCardData(
            title: '数据获取',
            flow: '异步加载 → 缓存 → 重建',
            icon: Icons.cloud_download,
            routeName: '/provider/future',
            chipLabel: 'FutureBuilder 缓存',
          ),
          _HomeCardData(
            title: '全局 Todo',
            flow: '列表变更 → notifyListeners',
            icon: Icons.checklist,
            routeName: '/provider/todo',
            chipLabel: 'ChangeNotifier',
          ),
        ],
      ),
      _RouteCategory(
        title: 'Riverpod',
        description: '容器化 Provider 图谱，无需 context',
        badge: '声明式',
        icon: Icons.sync_alt,
        routes: [
          _HomeCardData(
            title: 'StateNotifier 基础',
            flow: '事件 → state=new → 重建',
            icon: Icons.sync_alt,
            routeName: '/riverpod',
            chipLabel: '声明式图谱',
          ),
          _HomeCardData(
            title: '状态提升',
            flow: 'Provider 图谱共享',
            icon: Icons.vertical_align_top,
            routeName: '/riverpod/lifting',
            chipLabel: 'StateNotifierProvider',
          ),
          _HomeCardData(
            title: '数据获取',
            flow: 'FutureProvider → when()',
            icon: Icons.cloud_download,
            routeName: '/riverpod/future',
            chipLabel: '缓存与错误处理',
          ),
          _HomeCardData(
            title: '全局 Todo',
            flow: '列表不可变 → state 赋值广播',
            icon: Icons.checklist,
            routeName: '/riverpod/todo',
            chipLabel: 'StateNotifier',
          ),
        ],
      ),
      _RouteCategory(
        title: 'Bloc',
        description: '事件流驱动：Event → Bloc → emit(State)',
        badge: '事件驱动',
        icon: Icons.scatter_plot,
        routes: [
          _HomeCardData(
            title: 'flutter_bloc 基础',
            flow: 'Event → Bloc → emit(State) → 重建',
            icon: Icons.scatter_plot,
            routeName: '/bloc',
            chipLabel: '事件流 + 不可变状态',
          ),
        ],
      ),
    ];

    return LearningScaffold(
      title: '状态刷新流总览',
      interactiveDemo: SizedBox(
        height: 500,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final category in categories)
              _RouteCategoryCard(category: category),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解三大状态管理框架的核心机制',
            '对比 Provider、Riverpod、Bloc 的异同',
            '掌握状态刷新链路：事件 → 状态 → 通知 → UI 重建',
          ],
        ),
        ConceptChips(
          concepts: [
            'Provider',
            'Riverpod',
            'Bloc',
            'ChangeNotifier',
            'StateNotifier',
            '事件驱动',
          ],
        ),
        CodeSnippetCard(
          title: '状态刷新链路对比',
          code:
              '// Provider:  context.select + notifyListeners\n'
              '// Riverpod: ref.watch + state = new\n'
              '// Bloc:     context.read + emit(state)',
          explanation: '三种框架的核心理念不同，但都遵循"事件 → 状态 → UI"的刷新链路。',
        ),
        CommonPitfalls(
          pitfalls: [
            'Provider 的 context.select 只监听指定字段，避免不必要的重建',
            'Riverpod 的 Provider 是全局的，无需 Widget 树嵌套',
            'Bloc 的 Event/State 必须是不可变对象，使用 copyWith 或 freezed',
          ],
        ),
        ExerciseCard(
          task: '在 Provider "基础/粒度刷新"页面中观察 context.select 对重建粒度的影响。',
          hint: '打开调试控制台查看日志，点击加 1 按钮观察哪些 Widget 重建了。',
        ),
      ],
    );
  }
}

class _RouteCategory {
  const _RouteCategory({
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.routes,
  });
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final List<_HomeCardData> routes;
}

class _RouteCategoryCard extends StatelessWidget {
  const _RouteCategoryCard({required this.category});
  final _RouteCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      category.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
                final badge = Chip(
                  avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: Text(category.badge),
                );
                final avatar = CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(category.icon, color: theme.colorScheme.primary),
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(width: 12),
                          Expanded(child: heading),
                        ],
                      ),
                      const SizedBox(height: 8),
                      badge,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 16),
                    Expanded(child: heading),
                    badge,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (var i = 0; i < category.routes.length; i++) ...[
                  _RouteListTile(data: category.routes[i]),
                  if (i != category.routes.length - 1)
                    const Divider(height: 16),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteListTile extends StatelessWidget {
  const _RouteListTile({required this.data});
  final _HomeCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chip = Chip(
          avatar: const Icon(Icons.visibility, size: 16),
          label: Text(data.chipLabel),
        );
        final compact = constraints.maxWidth < 360;
        final subtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '刷新链路：${data.flow}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            if (compact) chip,
          ],
        );

        return ListTile(
          onTap: () => context.push('$_statusManageBaseRoute${data.routeName}'),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(data.icon, color: theme.colorScheme.secondary),
          ),
          title: Text(data.title, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: subtitle,
          ),
          trailing: compact ? null : chip,
        );
      },
    );
  }
}

class _HomeCardData {
  const _HomeCardData({
    required this.title,
    required this.flow,
    required this.icon,
    required this.routeName,
    required this.chipLabel,
  });
  final String title;
  final String flow;
  final IconData icon;
  final String routeName;
  final String chipLabel;
}
