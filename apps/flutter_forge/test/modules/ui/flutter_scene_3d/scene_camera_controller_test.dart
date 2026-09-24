import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_camera_controller.dart';

void main() {
  group('SceneCameraController', () {
    test('auto tour advances until direct manipulation takes over', () {
      final controller = SceneCameraController();

      controller.tick(const Duration(seconds: 1));
      controller.tick(const Duration(seconds: 2));
      expect(controller.yaw, closeTo(0.35, 0.001));

      controller.beginInteraction();
      controller.dragBy(const Offset(20, -10));
      final yawAfterDrag = controller.yaw;
      controller.tick(const Duration(seconds: 3));

      expect(controller.motionState, SceneMotionState.manual);
      expect(controller.yaw, yawAfterDrag);
      expect(
        controller.pitch,
        inInclusiveRange(
          SceneCameraController.minPitch,
          SceneCameraController.maxPitch,
        ),
      );
    });

    test(
      'coasting decays within the bounded duration and new input cancels it',
      () {
        final controller = SceneCameraController()..beginInteraction();
        controller.endInteraction(const Offset(700, 120));
        expect(controller.motionState, SceneMotionState.coasting);

        controller.tick(Duration.zero);
        controller.tick(const Duration(milliseconds: 900));
        expect(controller.motionState, SceneMotionState.manual);

        controller.endInteraction(const Offset(700, 0));
        expect(controller.motionState, SceneMotionState.coasting);
        controller.zoomBy(-0.2);
        expect(controller.motionState, SceneMotionState.manual);
      },
    );

    test('zoom, pitch, reduced motion, and reset remain bounded', () {
      final controller = SceneCameraController()..beginInteraction();
      controller.dragBy(const Offset(0, -10000));
      controller.zoomBy(-100);
      expect(controller.pitch, SceneCameraController.maxPitch);
      expect(controller.distance, SceneCameraController.minDistance);

      controller.setReducedMotion(true);
      controller.endInteraction(const Offset(900, 0));
      expect(controller.motionState, SceneMotionState.paused);

      controller.reset();
      expect(controller.yaw, 0);
      expect(controller.pitch, SceneCameraController.initialPitch);
      expect(controller.distance, SceneCameraController.initialDistance);
      expect(controller.motionState, SceneMotionState.paused);
    });

    test('expanded zoom range exposes a relative zoom scale', () {
      final controller = SceneCameraController();

      controller.zoomBy(-100);
      expect(controller.distance, 1.8);
      expect(controller.zoomScale, closeTo(4 / 1.8, 0.001));

      controller.zoomBy(100);
      expect(controller.distance, 12);
      expect(controller.zoomScale, closeTo(4 / 12, 0.001));
    });

    test(
      'basic mode rejects direct manipulation but keeps button controls',
      () {
        final controller = SceneCameraController()..setEnhancedMode(false);
        controller.beginInteraction();
        controller.dragBy(const Offset(100, 100));
        expect(controller.yaw, 0);
        expect(controller.pitch, SceneCameraController.initialPitch);

        controller.orbitBy(0.25);
        expect(controller.yaw, 0.25);
      },
    );

    test('mode changes normalize interrupted transition and coasting', () {
      final controller = SceneCameraController();

      controller.orbitBy(0.25);
      expect(controller.motionState, SceneMotionState.transitioning);
      controller.setEnhancedMode(false);
      expect(controller.motionState, SceneMotionState.manual);

      controller.setEnhancedMode(true);
      controller.beginInteraction();
      controller.endInteraction(const Offset(700, 0));
      expect(controller.motionState, SceneMotionState.coasting);
      controller.setEnhancedMode(false);
      expect(controller.motionState, SceneMotionState.manual);
    });
  });
}
