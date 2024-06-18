import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'mini_target.dart';

enum _State {
  incoming,
  floating,
}

class KamikazeUfoEnemy extends Component3D with AutoDispose, MiniScriptFunctions, MiniScript, MiniTarget {
  KamikazeUfoEnemy(this.onDefeated, {required super.world});

  final void Function() onDefeated;

  _State _state = _State.incoming;

  @override
  onLoad() async {
    final it = added(await spriteXY('alien-ufo-front.png', 0, 0));
    it.scale.setAll(3.0);
    worldPosition.setFrom(world.camera);
    worldPosition.z -= 1000;
    stateTime = random.nextDoubleLimit(4.0);
    life = 5;
  }

  var stateTime = 0.0;

  final targetOffsetZ = 150;

  final targetVelocity = Vector3(0, 0, 0);
  final velocity = Vector3(0, 0, 0);
  final relativePosition = Vector3(0, 0, 0);

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _State.incoming) {
      worldPosition.x = sin(stateTime) * 100;
      worldPosition.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
      worldPosition.z -= 300 * dt;
      stateTime += dt;
      if (worldPosition.z >= world.camera.z - targetOffsetZ) {
        _state = _State.floating;
        velocity.x = sin(stateTime) * 100;
        velocity.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
        velocity.z = worldPosition.z + 200 * dt;
        velocity.sub(worldPosition);
        relativePosition.setFrom(worldPosition);
        relativePosition.sub(world.camera);
        relativePosition.z += targetOffsetZ;
        targetVelocity.setFrom(velocity);
        logInfo(relativePosition);
        logInfo(targetVelocity);
        // targetVelocity.y = 0;
        // targetVelocity.z = 0;
        // velocity.y = 0;
        // velocity.z = 0;
      }
    }
    if (_state == _State.floating) {
      worldPosition.setFrom(world.camera);
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      final xSign = relativePosition.x.sign;
      // final ySign = relativePosition.y.sign;
      // final zSign = relativePosition.z.sign;

      relativePosition.add(velocity);

      // if (xSign != relativePosition.x.sign) {
      //   targetVelocity.x = xSign * (10 + random.nextDoubleLimit(10));
      // }
      // // if (ySign != relativePosition.y.sign) {
      // //   targetVelocity.y = -ySign * random.nextDoubleLimit(5);
      // // }
      // // if (zSign != relativePosition.z.sign) {
      // //   targetVelocity.z = -zSign * random.nextDoubleLimit(5);
      // // }
      //
      // velocity.lerp(targetVelocity, 0.3);
    }
  }

  @override
  void whenDefeated() {
    onDefeated();
  }
}
