class MachinePosition {
  const MachinePosition({
    this.x = 0,
    this.y = 0,
    this.feedRate = 0,
  });

  final double x;
  final double y;
  final double feedRate;

  MachinePosition copyWith({double? x, double? y, double? feedRate}) {
    return MachinePosition(
      x: x ?? this.x,
      y: y ?? this.y,
      feedRate: feedRate ?? this.feedRate,
    );
  }

  @override
  String toString() {
    return 'MachinePosition(x: $x, y: $y, F: $feedRate)';
  }
}
