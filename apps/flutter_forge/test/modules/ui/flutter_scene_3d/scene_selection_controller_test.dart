import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_selection_controller.dart';

void main() {
  test('selection can be replaced and cleared', () {
    final controller = SceneSelectionController();
    const cuboid = ScenePartHit(
      id: 'cuboid',
      label: '机身',
      centerX: -1.4,
      centerY: 0,
      centerZ: 0,
      distance: 3.2,
      normalX: 0,
      normalY: 1,
      normalZ: 0,
    );

    controller.select(cuboid);
    expect(controller.selected, cuboid);
    controller.clear();
    expect(controller.selected, isNull);
  });
}
