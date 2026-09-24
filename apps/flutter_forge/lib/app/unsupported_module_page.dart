import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/module_entry.dart';

class UnsupportedModulePage extends StatelessWidget {
  const UnsupportedModulePage({
    super.key,
    required this.module,
    required this.platform,
  });

  final ModuleEntry module;
  final AppPlatformSnapshot platform;

  @override
  Widget build(BuildContext context) {
    final supportedPlatforms = AppTargetPlatform.values
        .where((candidate) => candidate != AppTargetPlatform.unsupported)
        .where(
          (candidate) =>
              !module.platformSupport.excludedPlatforms.contains(candidate),
        )
        .map((candidate) => candidate.label)
        .join('、');

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '当前平台暂不支持此模块',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('当前平台：${platform.platform.label}'),
                const SizedBox(height: 8),
                Text(
                  supportedPlatforms.isEmpty
                      ? '当前没有开放的目标平台'
                      : '支持平台：$supportedPlatforms',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('返回模块目录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
