import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_category.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/module_catalog_utils.dart';
import 'category_navigation.dart';

class ModuleHomePage extends StatelessWidget {
  const ModuleHomePage({super.key, required this.modules});

  final List<ModuleEntry> modules;

  @override
  Widget build(BuildContext context) {
    const categories = ModuleCategory.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter 学习实验室')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryModules = modules
              .where((module) => module.category == category)
              .toList();

          if (categoryModules.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        CategoryNavigation.opensInNewWindow
                            ? Icons.open_in_new
                            : Icons.chevron_right,
                        size: 20,
                      ),
                      tooltip: '打开分类',
                      onPressed: () => CategoryNavigation.open(
                        context,
                        category: category,
                        modules: modules,
                      ),
                    ),
                  ],
                ),
              ),
              ...categoryModules.map(
                (module) => ModuleListTile(module: module),
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

class ModuleListTile extends StatelessWidget {
  const ModuleListTile({super.key, required this.module});

  final ModuleEntry module;

  Color _difficultyColor(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.beginner => Colors.green,
      Difficulty.intermediate => Colors.orange,
      Difficulty.advanced => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _difficultyColor(module.difficulty);
    final isAvailable = isModuleAvailable(module, defaultTargetPlatform);
    final textOpacity = isAvailable ? 1.0 : 0.55;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Opacity(opacity: textOpacity, child: Text(module.title)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              module.difficulty.label,
              style: TextStyle(
                fontSize: 11,
                color: difficultyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAvailable ? module.subtitle : '当前平台暂不支持此模块',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: textOpacity),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: module.concepts
                .map(
                  (concept) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(concept, style: const TextStyle(fontSize: 10)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '预计 ${module.estimatedMinutes} 分钟 · ${module.status.label}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600.withValues(alpha: textOpacity),
            ),
          ),
        ],
      ),
      trailing: Icon(
        isAvailable ? Icons.chevron_right : Icons.block,
        color: isAvailable ? null : Colors.grey,
      ),
      onTap: isAvailable ? () => context.push(module.path) : null,
    );
  }
}
