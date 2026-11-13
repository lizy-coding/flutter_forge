import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'module_discovery_session.dart';
import 'module_discovery_surface.dart';

/// Builds the module-discovery component catalog: schemas, renderers and the
/// local actions each generated component offers. Pure presentation over the
/// session's public surface — validation and stream state live in the session.
Catalog buildDiscoveryCatalog(ModuleDiscoverySession session) => Catalog([
  _item(
    'Group',
    {
      'children': S.list(items: S.string()),
      'title': S.string(),
      'layout': S.string(enumValues: ['list', 'compare']),
    },
    (c) {
      final data = c.data as Map;
      final children = [
        for (final id in data['children'] as List) c.buildChild(id as String),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data['title'] is String)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                data['title'] as String,
                style: Theme.of(c.buildContext).textTheme.titleMedium,
              ),
            ),
          if (data['layout'] == 'compare')
            LayoutBuilder(
              builder: (_, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: child,
                    ),
                ],
              ),
            )
          else
            ...children,
        ],
      );
    },
    required: ['children'],
  ),
  _item(
    'Note',
    {'text': S.string(maxLength: 600)},
    (c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text((c.data as Map)['text'] as String),
    ),
    required: ['text'],
  ),
  _item(
    'ModuleCard',
    {'moduleId': S.string(), 'reason': S.string(maxLength: 400)},
    (c) {
      final data = c.data as Map;
      final module = session.moduleByPath(data['moduleId'] as String)!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DiscoverySurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  module.title,
                  style: Theme.of(c.buildContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(module.subtitle),
                Text(
                  '${module.category.label} · ${module.difficulty.label} · ${module.estimatedMinutes} 分钟',
                ),
                const SizedBox(height: 8),
                Text(data['reason'] as String),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: session.busy
                        ? null
                        : () {
                            session.addRecord('本地打开：${module.path}');
                            session.openModule(module.path);
                          },
                    child: Text(session.moduleActionLabel(module)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    required: ['moduleId', 'reason'],
  ),
  _item(
    'CompareTable',
    {'moduleIds': S.list(items: S.string()), 'focus': S.string(maxLength: 120)},
    (c) {
      final data = c.data as Map;
      final selected = [
        for (final id in (data['moduleIds'] as List).whereType<String>())
          session.moduleByPath(id)!,
      ];
      final focus = data['focus'] as String?;
      final theme = Theme.of(c.buildContext);
      final colors = theme.colorScheme;
      TableRow row(String label, List<String> values) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final value in values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(value, style: theme.textTheme.bodySmall),
            ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DiscoverySurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Table(
                  columnWidths: const {0: FixedColumnWidth(72)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        const SizedBox(),
                        for (final module in selected)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  module.title,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: session.moduleActionLabel(module),
                                visualDensity: VisualDensity.compact,
                                onPressed: session.busy
                                    ? null
                                    : () {
                                        session.addRecord(
                                          '本地打开：${module.path}',
                                        );
                                        session.openModule(module.path);
                                      },
                                icon: const Icon(Icons.open_in_new, size: 16),
                              ),
                            ],
                          ),
                      ],
                    ),
                    row('分类', [
                      for (final module in selected) module.category.label,
                    ]),
                    row('难度', [
                      for (final module in selected) module.difficulty.label,
                    ]),
                    row('时长', [
                      for (final module in selected)
                        '${module.estimatedMinutes} 分钟',
                    ]),
                    row('平台', [
                      for (final module in selected)
                        module.isSupportedOn(session.platform)
                            ? '当前平台可用'
                            : '当前平台受限',
                    ]),
                    row('概念', [
                      for (final module in selected)
                        module.concepts.take(3).join('、'),
                    ]),
                  ],
                ),
                if (focus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '对比重点：$focus',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
    required: ['moduleIds'],
  ),
  _item(
    'LearningPath',
    {
      'title': S.string(maxLength: 40),
      'steps': S.list(
        items: S.object(
          properties: {
            'moduleId': S.string(),
            'goal': S.string(maxLength: 120),
          },
          required: ['moduleId', 'goal'],
        ),
      ),
    },
    (c) {
      final data = c.data as Map;
      final theme = Theme.of(c.buildContext);
      final colors = theme.colorScheme;
      final steps = [
        for (final step in (data['steps'] as List).whereType<Map>())
          (
            module: session.moduleByPath(step['moduleId'] as String?)!,
            goal: step['goal'] as String,
          ),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DiscoverySurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data['title'] is String)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      data['title'] as String,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                for (var index = 0; index < steps.length; index++)
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primaryContainer,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[index].goal,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    steps[index].module.category.icon,
                                    size: 16,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      steps[index].module.title,
                                      style: theme.textTheme.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: session.moduleActionLabel(
                                      steps[index].module,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: session.busy
                                        ? null
                                        : () {
                                            final path =
                                                steps[index].module.path;
                                            session.addRecord('本地打开：$path');
                                            session.openModule(path);
                                          },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                steps[index].module.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
    required: ['steps'],
  ),
  _item(
    'RecentHint',
    {'title': S.string(maxLength: 40), 'moduleIds': S.list(items: S.string())},
    (c) {
      final recents = [
        for (final path
            in ((c.data as Map)['moduleIds'] as List? ?? session.recentPaths))
          if (session.moduleByPath(path as String) case final module?) module,
      ].take(3).toList();
      if (recents.isEmpty) return const SizedBox.shrink();
      final theme = Theme.of(c.buildContext);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  ((c.data as Map)['title'] as String?) ?? '继续上次',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final module in recents)
                  ActionChip(
                    label: Text(module.title),
                    onPressed: session.busy
                        ? null
                        : () {
                            session.addRecord('本地打开：${module.path}');
                            session.openModule(module.path);
                          },
                  ),
              ],
            ),
          ],
        ),
      );
    },
  ),
  _item(
    'RefineChoice',
    {
      'label': S.string(maxLength: 60),
      'prompt': S.string(maxLength: 300),
      'filter': S.object(
        properties: {
          'by': S.string(enumValues: ['difficulty', 'category', 'concept']),
          'value': S.string(maxLength: 20),
        },
        required: ['by', 'value'],
      ),
    },
    (c) {
      final data = c.data as Map;
      final filter = data['filter'];
      final isLocal = filter is Map;
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton.icon(
            onPressed:
                session.busy || (!isLocal && session.pendingChoice != null)
                ? null
                : () {
                    final filter = data['filter'];
                    if (filter case Map<String, dynamic> filter
                        when filter['by'] is String &&
                            filter['value'] is String) {
                      session.applyLocalFilter(
                        by: filter['by'] as String,
                        value: filter['value'] as String,
                        label: data['label'] as String,
                      );
                    } else {
                      session.pendingChoice = data['prompt'] as String;
                      c.dispatchEvent(
                        UserActionEvent(
                          name: 'refineIntent',
                          sourceComponentId: c.id,
                          context: {'choice': session.pendingChoice!},
                        ),
                      );
                    }
                  },
            icon: Icon(
              isLocal ? Icons.filter_alt_outlined : Icons.north_east_rounded,
              size: 14,
            ),
            label: Text(data['label'] as String),
          ),
        ),
      );
    },
    required: ['label'],
  ),
], catalogId: discoveryCatalog);

CatalogItem _item(
  String name,
  Map<String, Schema> properties,
  Widget Function(CatalogItemContext) builder, {
  List<String> required = const [],
}) => CatalogItem(
  name: name,
  dataSchema: S.object(properties: properties, required: required),
  widgetBuilder: builder,
);
