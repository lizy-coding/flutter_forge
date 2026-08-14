/// 模块分类
enum ModuleCategory {
  basic('基础机制'),
  async('异步并发'),
  state('状态管理'),
  ui('UI 与动效'),
  popupTable('弹窗与列表'),
  platform('网络与平台');

  const ModuleCategory(this.label);
  final String label;
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
