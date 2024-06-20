import 'dart:math';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import 'captain.dart';

class CaptainCam extends Component {
  Captain? follow;

  final currentPosition = Vector3(0, 10, 50);

  double slowDownSpeed = baseSpeed * 0.75;

  @override
  void update(double dt) {
    super.update(dt);

    world.camera.setFrom(currentPosition);
    world.camera.z += 25;

    final f = follow;
    if (f == null) return;

    if (f.isMounted) {
      currentPosition.setFrom(f.worldPosition);
      currentPosition.x = currentPosition.x / 1.2;
      currentPosition.y = (currentPosition.y - midHeight) / 2 * 1.2 + midHeight;
    } else if (f.instantKill) {
      world.camera.setFrom(currentPosition);
      world.camera.z += 50;

      // captain is dead, so we do this here:
      if (f.shakeTime > 0) {
        f.shakeTime -= dt;
      } else {
        removeFromParent();
      }
    } else {
      currentPosition.z += slowDownSpeed * dt;
      if (slowDownSpeed < 0) {
        slowDownSpeed -= baseSpeed / 3 * dt;
      } else {
        removeFromParent();
      }
    }

    if (f.shakeTime > 0) {
      currentPosition.x += sin(f.shakeTime * 30) * 3;
      currentPosition.y += cos(f.shakeTime * 23) * 3;
    }
  }
}
