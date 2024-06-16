import 'dart:math';

import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
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

class UfoEnemy extends Component3D with AutoDispose, MiniScriptFunctions, MiniScript, MiniTarget {
  //
  UfoEnemy(this.onDefeated, {required super.world});

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

  final targetOffsetZ = 125;

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _State.incoming) {
      worldPosition.x = sin(stateTime) * 100;
      worldPosition.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
      worldPosition.z -= 200 * dt;
      stateTime += dt;
      if (worldPosition.z >= world.camera.z - targetOffsetZ) _state = _State.floating;
    }
    if (_state == _State.floating) {
      worldPosition.x = sin(stateTime) * 200;
      worldPosition.y = midHeight + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 100;
      stateTime += dt;
      worldPosition.z = world.camera.z - targetOffsetZ + cos(stateTime) * 20;
    }
  }

  @override
  void whenDefeated() {
    onDefeated();
  }
}
