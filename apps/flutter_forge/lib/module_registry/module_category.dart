import 'package:flutter/material.dart';

/// 模块分类
enum ModuleCategory {
  basic('基础机制', Icons.account_tree_outlined),
  async('异步并发', Icons.bolt_outlined),
  state('架构与状态', Icons.hub_outlined),
  ui('UI 与动效', Icons.palette_outlined),
  popupTable('弹窗与列表', Icons.table_chart_outlined),
  platform('网络与平台', Icons.devices_outlined);

  const ModuleCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 难度等级
enum Difficulty {
  beginner('入门'),
  intermediate('进阶'),
  advanced('实战');

  const Difficulty(this.label);
  final String label;
}

/// 模块状态
enum ModuleStatus {
  pending('待整改'),
  ready('可学习'),
  recommended('推荐');

  const ModuleStatus(this.label);
  final String label;
}
