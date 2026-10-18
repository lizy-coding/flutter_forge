enum ScenePartShape { cuboid, sphere, cylinder }

class ScenePartDefinition {
  const ScenePartDefinition({
    required this.id,
    required this.label,
    required this.shape,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.width = 1,
    this.height = 1,
    this.depth = 1,
  });

  final String id;
  final String label;
  final ScenePartShape shape;
  final double x;
  final double y;
  final double z;
  final double width;
  final double height;
  final double depth;
}
