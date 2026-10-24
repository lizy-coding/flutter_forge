import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'creator_profile.dart';
import 'theme/forge_theme_tokens.dart';

class CreatorHomePage extends StatelessWidget {
  const CreatorHomePage({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('creator-home-scroll'),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关于 Flutter Forge',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('可运行、可拆解、可验证的 Flutter 学习工坊。'),
            const SizedBox(height: 24),
            const _CreatorFooter(),
          ],
        ),
      ),
    ),
  );
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
        color: context.forgeColors.glass
            ? colors.surfaceContainerLow.withValues(alpha: 0.58)
            : colors.surfaceContainerLow,
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
