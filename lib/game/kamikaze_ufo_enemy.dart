import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import '../scripting/game_script.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'damage_target.dart';
import 'extras.dart';
import 'fragment.dart';

enum _State {
  incoming,
  attacking,
}

class KamikazeUfoEnemy extends Component3D with AutoDispose, GameScriptFunctions, GameScript, DamageTarget {
  KamikazeUfoEnemy(this.onDefeated, this.captain, {required super.world}) {
    anchor = Anchor.bottomCenter;
  }

  final void Function() onDefeated;
  final Component3D captain;

  _State _state = _State.incoming;

  bool readyToAttack = false;

  late final SpriteComponent _sprite;

  @override
  onLoad() async {
    _sprite = added(await spriteXY('alien-ufo-front.png', 0, 0, Anchor.bottomCenter));
    _sprite.scale.setAll(3.0);
    worldPosition.setFrom(world.camera);
    worldPosition.z -= 5000;
    stateTime = random.nextDoubleLimit(4.0);
    life = 3;
  }

  var stateTime = 0.0;

  final targetOffsetZ = 150;

  final targetVelocity = Vector3(0, 0, 0);
  final velocity = Vector3(0, 0, 0);
  final relativePosition = Vector3(0, 0, -5000);
  var incomingSpeed = 2500.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _State.incoming) {
      worldPosition.setFrom(world.camera);
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      relativePosition.x = sin(stateTime) * 100;
      relativePosition.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
      relativePosition.z += incomingSpeed * dt;
      incomingSpeed = relativePosition.z.abs().clamp(300, 2500);

      stateTime += dt;

      if (worldPosition.z >= world.camera.z - targetOffsetZ) {
        _state = _State.attacking;
        velocity.x = sin(stateTime) * 100;
        velocity.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
        velocity.z = -incomingSpeed;
        velocity.sub(relativePosition);
        velocity.z = -velocity.z;
        targetVelocity.setFrom(velocity);
        logInfo(relativePosition);
        logInfo(targetVelocity);

        readyToAttack = true;
      }
    }
    if (_state == _State.attacking) {
      worldPosition.setFrom(world.camera);
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      relativePosition.add(velocity * dt);

      bool remove = false;
      if (position.x < -20 || position.x > gameWidth + 20) remove = true;
      if (position.y > gameHeight + 20) remove = true;
      if (worldPosition.z > world.camera.z - 20) remove = true;
      if (remove) {
        _removeNow();
        return;
      }

      final xClose = (captain.worldPosition.x - worldPosition.x).abs() < 50;
      final yClose = (captain.worldPosition.y - worldPosition.y).abs() < 50;
      final zClose = (captain.worldPosition.z - worldPosition.z).abs() < 20;
      if (xClose && yClose && zClose) {
        (captain as DamageTarget).applyDamage(collision: 5);
        applyDamage(collision: life);
      }
    }
  }

  void _removeNow() {
    removeFromParent();
    onDefeated();
  }

  final check = Vector3.zero();

  @override
  void whenDefeated() {
    onDefeated();

    final i = _sprite.sprite?.image;
    if (i == null) return;

    final pieces = sheet(i, 5, 5);
    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 5; j++) {
        final dx = (i - 2) * 10.0;
        final dy = (j - 2) * 10.0;
        velocity.setValues(0, 0, -5);
        parent?.add(Fragment(
          worldPosition,
          velocity,
          pieces.getSprite(4 - j, i),
          dx,
          dy,
          world: world,
        ));
      }
    }

    spawnExtra(worldPosition);
  }

  @override
  void whenHit() {}
}
