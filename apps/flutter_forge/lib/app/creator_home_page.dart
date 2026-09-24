import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../module_registry/module_category.dart';
import 'creator_profile.dart';

class CreatorHomePage extends StatelessWidget {
  const CreatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.42),
            colors.surface,
            colors.tertiaryContainer.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: SingleChildScrollView(
        key: const ValueKey('creator-home-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroSection(wide: wide),
                    const SizedBox(height: 40),
                    Text(
                      '从一个方向开始',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '每个主题都由可运行示例、关键概念和实践路径组成。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CategoryGrid(wide: wide),
                    const SizedBox(height: 40),
                    const _CreatorFooter(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              'FLUTTER LEARNING WORKSPACE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '把 Flutter 学习\n变成一次次实践',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Flutter Forge 汇集跨平台、状态管理、异步与 UI 实验。不是孤立的 Demo，而是一座可以运行、拆解和验证的学习工坊。',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const ValueKey('start-learning'),
              onPressed: () =>
                  context.go('/category/${ModuleCategory.basic.name}'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('开始学习'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('creator-github-link'),
              onPressed: () => launchUrl(
                flutterForgeCreator.githubUri,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.code_rounded),
              label: const Text('GitHub'),
            ),
          ],
        ),
      ],
    );

    const highlights = _HighlightPanel();
    return Container(
      padding: EdgeInsets.all(wide ? 36 : 24),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: introduction),
                const SizedBox(width: 40),
                const Expanded(flex: 4, child: highlights),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [introduction, const SizedBox(height: 32), highlights],
            ),
    );
  }
}

class _HighlightPanel extends StatelessWidget {
  const _HighlightPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const highlights = [
      (Icons.devices_rounded, '跨平台', '移动、桌面与 Web'),
      (Icons.touch_app_rounded, '可交互', '从代码走向真实体验'),
      (Icons.verified_outlined, '可验证', '测试与平台证据同行'),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var index = 0; index < highlights.length; index++) ...[
            _HighlightRow(data: highlights[index]),
            if (index != highlights.length - 1)
              Divider(height: 1, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.data});

  final (IconData, String, String) data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.$1, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.$2, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  data.$3,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ModuleCategory.values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        mainAxisExtent: 118,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final category = ModuleCategory.values[index];
        return _CategoryCard(category: category, index: index);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.index});

  final ModuleCategory category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = [
      colors.primary,
      colors.tertiary,
      colors.secondary,
    ][index % 3];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('home-category:${category.name}'),
        onTap: () => context.go('/category/${category.name}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(category.icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_outward_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorFooter extends StatelessWidget {
  const _CreatorFooter();

  @override
  Widget build(BuildContext context) {
    final profile = flutterForgeCreator;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final identity = _CreatorIdentity(profile: profile);
          final details = _CreatorDetails(profile: profile);
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 220, child: identity),
                    const SizedBox(width: 32),
                    Expanded(child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 24), details],
                );
        },
      ),
    );
  }
}

class _CreatorIdentity extends StatelessWidget {
  const _CreatorIdentity({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            profile.name.substring(0, 1).toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '@${profile.handle}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  const Text('深圳'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreatorDetails extends StatelessWidget {
  const _CreatorDetails({required this.profile});

  final CreatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.headline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final area in profile.focusAreas)
              Chip(visualDensity: VisualDensity.compact, label: Text(area)),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ProfileLink(
              key: const ValueKey('profile-github-link'),
              icon: Icons.code_rounded,
              label: 'GitHub',
              uri: profile.githubUri,
            ),
            _ProfileLink(
              key: const ValueKey('profile-juejin-link'),
              icon: Icons.article_outlined,
              label: '掘金 · 人形打码机',
              uri: profile.juejinUri,
            ),
            _ProfileLink(
              key: const ValueKey('profile-yuque-link'),
              icon: Icons.menu_book_outlined,
              label: '语雀',
              uri: profile.yuqueUri,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    super.key,
    required this.icon,
    required this.label,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
