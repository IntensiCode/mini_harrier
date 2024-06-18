import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import 'captain.dart';

class CaptainCam extends Component {
  Captain? follow;

  final currentPosition = Vector3(0, 10, 50);

  @override
  void update(double dt) {
    super.update(dt);

    world.camera.setFrom(currentPosition);
    world.camera.z += 25;

    final f = follow;
    if (f == null) return;

    currentPosition.setFrom(f.worldPosition);
    currentPosition.x = currentPosition.x / 3;
    currentPosition.y = (currentPosition.y - midHeight) / 4 + midHeight;
  }
}
