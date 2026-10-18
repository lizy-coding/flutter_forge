import 'package:flutter/foundation.dart';

class ScenePartHit {
  const ScenePartHit({
    required this.id,
    required this.label,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.distance,
    required this.normalX,
    required this.normalY,
    required this.normalZ,
  });

  final String id;
  final String label;
  final double centerX;
  final double centerY;
  final double centerZ;
  final double distance;
  final double normalX;
  final double normalY;
  final double normalZ;
}

class SceneSelectionController extends ChangeNotifier {
  ScenePartHit? _selected;

  ScenePartHit? get selected => _selected;

  void select(ScenePartHit hit) {
    _selected = hit;
    notifyListeners();
  }

  void clear() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }
}
