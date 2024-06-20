import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import '../game/extras.dart';
import '../game/fragment.dart';
import '../scripting/game_script.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'damage_target.dart';

enum _State {
  incoming,
  floating,
  fly_off,
}

class UfoEnemy extends Component3D with AutoDispose, GameScriptFunctions, GameScript, DamageTarget {
  UfoEnemy(this.onDefeated, {required super.world}) {
    anchor = Anchor.bottomCenter;
  }

  final void Function(bool) onDefeated;

  _State _state = _State.incoming;

  bool readyToAttack = false;

  flyOff() => _state = _State.fly_off;

  late final SpriteComponent _sprite;

  @override
  onLoad() async {
    _sprite = added(await spriteXY('alien-ufo-front.png', 0, 0, Anchor.bottomCenter));
    _sprite.scale.setAll(3.0);
    worldPosition.setFrom(world.camera);
    worldPosition.x = 0;
    worldPosition.z -= 5000;
    stateTime = random.nextDoubleLimit(4.0);
    life = 10;
  }

  var stateTime = 0.0;

  final targetOffsetZ = 150;

  final targetVelocity = Vector3(0, 0, 0);
  final velocity = Vector3(0, 0, 0);
  final relativePosition = Vector3(0, 0, -3000);
  var incomingSpeed = 2500.0;

  double targetTracking = 0;

  @override
  void update(double dt) {
    super.update(dt);

    targetTracking = targetTracking + (world.camera.x - targetTracking) * 0.5 * dt;

    if (_state == _State.incoming) {
      worldPosition.setFrom(world.camera);
      worldPosition.x = targetTracking;
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      relativePosition.x = sin(stateTime) * 100;
      relativePosition.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
      relativePosition.z += incomingSpeed * dt;
      incomingSpeed = relativePosition.z.abs().clamp(300, 2500) * 1.5 * difficulty;

      stateTime += dt;

      if (worldPosition.z >= world.camera.z - targetOffsetZ) {
        _state = _State.floating;
        velocity.x = sin(stateTime) * 100;
        velocity.y = 100 + sin(stateTime * 1.4) * cos(stateTime * 1.8) * 75;
        velocity.z = 250 * dt;
        velocity.sub(relativePosition);
        velocity.z = -velocity.z;
        targetVelocity.setFrom(velocity);
        logInfo(relativePosition);
        logInfo(targetVelocity);
      }
    }
    if (_state == _State.fly_off) {
      targetVelocity.setValues(0, 20, 0);

      worldPosition.setFrom(world.camera);
      worldPosition.x = 0;
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      readyToAttack = false;

      relativePosition.add(velocity);
      relativePosition.z -= 20 * dt;

      velocity.lerp(targetVelocity, 0.01);

      if (relativePosition.y > 10000) removeFromParent();
      if (position.y < -50) removeFromParent();
    }
    if (_state == _State.floating) {
      worldPosition.setFrom(world.camera);
      worldPosition.x = targetTracking;
      worldPosition.add(relativePosition);
      worldPosition.z -= targetOffsetZ;

      readyToAttack = relativePosition.z < 0;

      relativePosition.add(velocity);

      const xSpeed = 3.0;
      if (relativePosition.x < -200 && targetVelocity.x < 0) {
        targetVelocity.x = xSpeed + random.nextDoubleLimit(xSpeed);
      }
      if (relativePosition.x > 200 && targetVelocity.x > 0) {
        targetVelocity.x = -xSpeed - random.nextDoubleLimit(xSpeed);
      }
      if (targetVelocity.x.abs() < 0.5) {
        targetVelocity.x = 0.5 + random.nextDoubleLimit(0.5);
        if (random.nextBool()) targetVelocity.x *= -1;
      }

      if (relativePosition.y < 40 && targetVelocity.y < 0) {
        targetVelocity.y = 2 + random.nextDoubleLimit(2);
      }
      if (relativePosition.y > 160 && targetVelocity.y > 0) {
        targetVelocity.y = -2 - random.nextDoubleLimit(2);
      }
      if (targetVelocity.y.abs() < 0.5) {
        targetVelocity.y = 0.5 + random.nextDoubleLimit(0.5);
        if (random.nextBool()) targetVelocity.y *= -1;
      }

      if (relativePosition.z < -20 && targetVelocity.z < 0) {
        targetVelocity.z = 2 + random.nextDoubleLimit(2);
      }
      if (relativePosition.z > 10 && targetVelocity.z > 0) {
        targetVelocity.z = -2 - random.nextDoubleLimit(2);
      }
      if (targetVelocity.z.abs() < 0.5) {
        targetVelocity.z = 0.5 + random.nextDoubleLimit(0.5);
        if (random.nextBool()) targetVelocity.z *= -1;
      }

      velocity.lerp(targetVelocity, 0.75 / tps);

      final buddies = parent?.children.whereType<UfoEnemy>();
      if (buddies == null) return;

      bool perceivedCollision(UfoEnemy other) {
        if (other == this) return false;
        // final dist2 = worldPosition.distanceToSquared(other.worldPosition);
        // return dist2 < 3000;
        check.setFrom(other.worldPosition);
        check.sub(worldPosition);
        check.absolute();
        if (check.x > 80) return false;
        if (check.y > 80) return false;
        if (check.z > 20) return false;
        return true;
      }

      for (final it in buddies) {
        if (it == this) continue;
        if (perceivedCollision(it)) {
          check.setFrom(it.worldPosition);
          check.sub(worldPosition);
          check.normalize();
          if (check.angleTo(velocity).abs() < pi / 4) {
            check.negate();
            check.sub(velocity);
            check.normalize();
            check.scale(velocity.length);
            velocity.setFrom(check);
            it.velocity.setFrom(check);
            it.velocity.negate();
            applyDamage(collision: 0.05);
          }
          // final angle = check.angleTo(velocity);
          // logInfo(angle);
        }
      }
    }
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
