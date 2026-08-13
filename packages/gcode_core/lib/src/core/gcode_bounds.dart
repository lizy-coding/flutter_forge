class GcodeBounds {
  const GcodeBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  static const zero = GcodeBounds(minX: 0, maxX: 0, minY: 0, maxY: 0);

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  GcodeBounds expand(double x, double y) {
    return GcodeBounds(
      minX: x < minX ? x : minX,
      maxX: x > maxX ? x : maxX,
      minY: y < minY ? y : minY,
      maxY: y > maxY ? y : maxY,
    );
  }
}
