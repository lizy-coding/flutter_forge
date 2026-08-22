/// 动画配置类，用于封装所有动画控制参数
class AnimationConfig {
  final int animationDuration; // 动画持续时间（毫秒）
  final double flyingItemOffset; // 飞入点的偏移量
  final double flyingItemPadding; // 飞入点内边距
  final double flyingItemRadius; // 飞入点圆角
  final double flyingSpeed; // 飞入动效速度倍数（1.0为正常速度）

  const AnimationConfig({
    this.animationDuration = 1500,
    this.flyingItemOffset = 30.0,
    this.flyingItemPadding = 8.0,
    this.flyingItemRadius = 8.0,
    this.flyingSpeed = 1.0,
  });

  /// 创建一个可修改的配置副本
  AnimationConfig copyWith({
    int? animationDuration,
    double? flyingItemOffset,
    double? flyingItemPadding,
    double? flyingItemRadius,
    double? flyingSpeed,
  }) {
    return AnimationConfig(
      animationDuration: animationDuration ?? this.animationDuration,
      flyingItemOffset: flyingItemOffset ?? this.flyingItemOffset,
      flyingItemPadding: flyingItemPadding ?? this.flyingItemPadding,
      flyingItemRadius: flyingItemRadius ?? this.flyingItemRadius,
      flyingSpeed: flyingSpeed ?? this.flyingSpeed,
    );
  }

  /// 转换为Map，用于序列化
  Map<String, dynamic> toMap() {
    return {
      'animationDuration': animationDuration,
      'flyingItemOffset': flyingItemOffset,
      'flyingItemPadding': flyingItemPadding,
      'flyingItemRadius': flyingItemRadius,
      'flyingSpeed': flyingSpeed,
    };
  }

  /// 从Map创建实例，用于反序列化
  factory AnimationConfig.fromMap(Map<String, dynamic> map) {
    return AnimationConfig(
      animationDuration: map['animationDuration'],
      flyingItemOffset: map['flyingItemOffset'],
      flyingItemPadding: map['flyingItemPadding'],
      flyingItemRadius: map['flyingItemRadius'],
      flyingSpeed: map['flyingSpeed'] ?? 1.0,
    );
  }
}
