import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'creator_profile.dart';

class CreatorHomePage extends StatelessWidget {
  const CreatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = flutterForgeCreator;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      child: Text(
                        profile.name.substring(0, 1).toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      profile.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final area in profile.focusAreas)
                          Chip(label: Text(area)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      key: const ValueKey('creator-github-link'),
                      onPressed: () => launchUrl(
                        profile.githubUri,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.code),
                      label: const Text('访问 GitHub'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
