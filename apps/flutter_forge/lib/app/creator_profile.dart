import 'package:flutter/material.dart';

@immutable
class CreatorProfile {
  const CreatorProfile({
    required this.name,
    required this.handle,
    required this.headline,
    required this.summary,
    required this.focusAreas,
    required this.githubUri,
    required this.juejinUri,
    required this.yuqueUri,
  });

  final String name;
  final String handle;
  final String headline;
  final String summary;
  final List<String> focusAreas;
  final Uri githubUri;
  final Uri juejinUri;
  final Uri yuqueUri;
}

final CreatorProfile flutterForgeCreator = CreatorProfile(
  name: 'Lizy',
  handle: 'lizy-coding',
  headline: 'AI Native Flutter Infrastructure Engineer',
  summary: '专注构建 AI 驱动的 Flutter 工程体系与跨平台基础架构。相比孤立的业务功能，更关注可复用、可扩展、可持续演进的工程系统。',
  focusAreas: const [
    'Flutter 跨平台基础架构',
    'AI Engineering Workflow',
    '高性能渲染与稳定性',
    '复杂系统架构治理',
  ],
  githubUri: Uri.parse('https://github.com/lizy-coding'),
  juejinUri: Uri.parse('https://juejin.cn/user/2085122730895063/posts'),
  yuqueUri: Uri.parse('https://www.yuque.com/diligent_coding/flutter'),
);
