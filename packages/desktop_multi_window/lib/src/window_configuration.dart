class WindowConfiguration {
  const WindowConfiguration({
    required this.arguments,
    this.hiddenAtLaunch = true,
    this.enableFlutterGpu = false,
  });

  /// The arguments passed to the new window.
  final String arguments;

  final bool hiddenAtLaunch;
  final bool enableFlutterGpu;

  factory WindowConfiguration.fromJson(Map<String, dynamic> json) {
    return WindowConfiguration(
      arguments: json['arguments'] as String? ?? '',
      hiddenAtLaunch: json['hiddenAtLaunch'] as bool? ?? false,
      enableFlutterGpu: json['enableFlutterGpu'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arguments': arguments,
      'hiddenAtLaunch': hiddenAtLaunch,
      'enableFlutterGpu': enableFlutterGpu,
    };
  }

  @override
  String toString() {
    return 'WindowConfiguration(arguments: $arguments, hiddenAtLaunch: $hiddenAtLaunch, enableFlutterGpu: $enableFlutterGpu)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowConfiguration &&
        other.arguments == arguments &&
        other.hiddenAtLaunch == hiddenAtLaunch &&
        other.enableFlutterGpu == enableFlutterGpu;
  }

  @override
  int get hashCode {
    return Object.hash(arguments, hiddenAtLaunch, enableFlutterGpu);
  }
}
