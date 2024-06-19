import 'dart:math';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import 'captain.dart';

class CaptainCam extends Component {
  Captain? follow;

  final currentPosition = Vector3(0, 10, 50);

  double slowDownSpeed = 40;

  @override
  void update(double dt) {
    super.update(dt);

    world.camera.setFrom(currentPosition);
    world.camera.z += 25;

    final f = follow;
    if (f == null) return;

    if (f.isMounted) {
      currentPosition.setFrom(f.worldPosition);
      currentPosition.x = currentPosition.x / 3;
      currentPosition.y = (currentPosition.y - midHeight) / 2 + midHeight;
      if (f.shakeTime > 0) {
        currentPosition.x += sin(f.shakeTime * 30) * 3;
        currentPosition.y += cos(f.shakeTime * 23) * 3;
      }
    } else {
      currentPosition.z -= slowDownSpeed * dt;
      slowDownSpeed -= slowDownSpeed * 0.9 * dt;
      if (slowDownSpeed < 10) removeFromParent();
    }
  }
}
