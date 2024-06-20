import 'dart:math';

import 'package:flame/components.dart';
import 'package:mini_harrier/core/messaging.dart';
import 'package:mini_harrier/scripting/game_script_functions.dart';
import 'package:mini_harrier/util/auto_dispose.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import 'captain.dart';

enum _State {
  waiting,
  following,
  instant_kill,
  slow_down,
}

class CaptainCam extends Component with AutoDispose, GameScriptFunctions {
  Captain? follow;

  final currentPosition = Vector3(0, 10, 50);

  double slowDownSpeed = baseSpeed * 0.75;

  final basePos = Vector3.zero();

  _State _state = _State.waiting;

  @override
  void onMount() {
    super.onMount();
    onMessage<StageComplete>((_) => _state = _State.slow_down);
  }

  @override
  void update(double dt) {
    super.update(dt);

    world.camera.setFrom(currentPosition);
    world.camera.z += 25;

    if (_state == _State.waiting) {
      final f = follow;
      if (f == null) return;
      _state = _State.following;
    }

    if (_state == _State.following) {
      if (follow!.instantKill) {
        _state = _State.instant_kill;
      } else if (follow!.isMounted == false) {
        _state = _State.slow_down;
        follow = null;
      } else {
        currentPosition.setFrom(follow!.worldPosition);
        currentPosition.x = currentPosition.x / 1.2;
        currentPosition.y = (currentPosition.y - midHeight) / 2 * 1.2 + midHeight;

        basePos.setFrom(currentPosition);
      }
    }

    if (_state == _State.instant_kill) {
      if (follow!.shakeTime > 0) {
        follow!.shakeTime -= dt;
      } else {
        removeFromParent();
      }
    }

    if (_state == _State.slow_down) {
      currentPosition.z += slowDownSpeed * dt;
      currentPosition.y += 300 * dt;
      basePos.setFrom(currentPosition);
      if (slowDownSpeed < 0) {
        slowDownSpeed -= baseSpeed / 3 * dt;
      } else {
        removeFromParent();
      }
    }

    if (follow != null && follow!.shakeTime > 0) {
      currentPosition.setFrom(basePos);
      currentPosition.x += sin(follow!.shakeTime * 30) * 3;
      currentPosition.y += cos(follow!.shakeTime * 23) * 3;
    }
  }
}
