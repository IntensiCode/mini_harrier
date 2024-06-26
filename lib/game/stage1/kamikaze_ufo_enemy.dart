import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../../core/common.dart';
import '../../core/mini_3d.dart';
import '../../scripting/game_script.dart';
import '../../scripting/game_script_functions.dart';
import '../../util/auto_dispose.dart';
import '../../util/extensions.dart';
import '../../util/random.dart';
import '../damage_target.dart';
import '../extras.dart';
import '../fragment.dart';

enum _State {
  incoming,
  attacking,
}

class KamikazeUfoEnemy extends Component3D with AutoDispose, GameScriptFunctions, GameScript, DamageTarget {
  KamikazeUfoEnemy(this.onDefeated, this.captain, {required super.world}) {
    anchor = Anchor.bottomCenter;
  }

  final void Function(bool) onDefeated;
  final Component3D captain;

  _State _state = _State.incoming;

  bool readyToAttack = false;

  late final SpriteComponent _sprite;

  @override
  void onMount() {
    super.onMount();
    xBase = random.nextDoublePM(300);
  }

  @override
  onLoad() async {
    _sprite = added(await spriteXY('alien-ufo-front.png', 0, 0, Anchor.bottomCenter));
    _sprite.scale.setAll(3.0);
    worldPosition.setFrom(world.camera);
    worldPosition.x = 0;
    worldPosition.z -= 5000;
    stateTime = random.nextDoubleLimit(4.0);
    life = 5;
  }

  var stateTime = 0.0;

  final targetOffsetZ = 1000;

  final targetVelocity = Vector3(0, 0, 0);
  final velocity = Vector3(0, 0, 0);
  final relativePosition = Vector3(0, 0, -5000);
  var incomingSpeed = 3500.0;

  double xBase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _State.incoming) {
      worldPosition.setFrom(world.camera);
      worldPosition.x = 0;
      worldPosition.y = 0;
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      relativePosition.x = xBase + sin(stateTime) * 100;
      relativePosition.y = midHeight + sin(stateTime * 1.4) * cos(stateTime * 1.8) * midHeight / 2;
      relativePosition.z += incomingSpeed * dt;
      incomingSpeed = relativePosition.z.abs().clamp(300, 2500);

      stateTime += dt;

      if (worldPosition.z >= world.camera.z - targetOffsetZ) {
        _state = _State.attacking;
        velocity.x = sin(stateTime) * 100;
        velocity.y = midHeight + sin(stateTime * 1.4) * cos(stateTime * 1.8) * midHeight / 2;
        velocity.z = -incomingSpeed;
        velocity.sub(relativePosition);
        velocity.z = -velocity.z;
        logInfo(relativePosition);
        logInfo(targetVelocity);

        readyToAttack = true;
      }
    }
    if (_state == _State.attacking) {
      worldPosition.setFrom(world.camera);
      worldPosition.x = 0;
      worldPosition.y = 0;
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      if (captain.distance3D(this) > 500) {
        targetVelocity.setFrom(captain.worldPosition);
        targetVelocity.sub(worldPosition);
        targetVelocity.z = velocity.z;
      }

      final diff = Vector3.copy(targetVelocity);
      diff.sub(velocity);
      diff.normalize();
      diff.scale(dt * 3000);
      diff.x *= 0.2;
      diff.z *= 1.2;
      velocity.add(diff);

      relativePosition.add(velocity * dt);
      if (relativePosition.y < 10) relativePosition.y = 10;

      bool remove = false;
      if (position.x < -20 || position.x > gameWidth + 20) remove = true;
      if (position.y > gameHeight + 20) remove = true;
      if (worldPosition.z > world.camera.z - 20) remove = true;
      if (remove) {
        _removeNow(false);
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

  void _removeNow(bool destroyed) {
    removeFromParent();
    onDefeated(destroyed);
  }

  final check = Vector3.zero();

  @override
  void whenDefeated() {
    onDefeated(true);

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
