import 'package:flutter/material.dart';

@immutable
class CreatorProfile {
  const CreatorProfile({
    required this.name,
    required this.headline,
    required this.summary,
    required this.focusAreas,
    required this.githubUri,
  });

  final String name;
  final String headline;
  final String summary;
  final List<String> focusAreas;
  final Uri githubUri;
}

final CreatorProfile flutterForgeCreator = CreatorProfile(
  name: 'Lizy',
  headline: 'IoT · Flutter · AI Agent Engineering',
  summary:
      '长期从事 IoT 与 Flutter 跨平台开发，关注设备连接、平台能力、复杂状态治理，以及可控制、可验证、可持续的 Agent 工程流程。',
  focusAreas: const ['IoT 设备与系统能力', 'Flutter 跨平台与 Plugin', 'AI Agent 编排与工程治理'],
  githubUri: Uri.parse('https://github.com/lizy-coding'),
);
