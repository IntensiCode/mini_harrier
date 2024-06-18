import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_game_keys.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'fragment.dart';
import 'mini_target.dart';
import 'swirl_weapon.dart';

enum CaptainState {
  defeated,
  intro,
  playing,
}

class Captain extends Component3D with AutoDispose, MiniScriptFunctions, KeyboardHandler, MiniGameKeys, MiniTarget {
  Captain({required super.world}) {
    worldPosition.x = 0;
    worldPosition.y = 50;
    worldPosition.z = 25;
    life = maxLife;
  }

  final maxLife = 25.0;

  late final weapon = SwirlWeapon(this, () => primaryFire, parent!, world);

  late CaptainState state = CaptainState.intro;

  late final SpriteSheet _sheet;
  late final SpriteComponent _sprite;

  @override
  onLoad() async {
    _sheet = sheet(await image('captain_sprite.png'), 3, 5);
    _sprite = spriteSXY(_sheet.getSprite(1, 1), 0, 0, Anchor.bottomCenter);
    _sprite.scale.setAll(2);
    add(fadeIn(_sprite));
    add(weapon);
  }

  @override
  void update(double dt) {
    if (debug.value && secondaryFire) applyDamage(collision: life);

    super.update(dt);
    worldPosition.add(velocity * dt);
    if (state == CaptainState.playing) _playing(dt);
    if (shakeTime > 0) {
      shakeTime -= dt;
    } else {
      shakeTime = 0;
    }
  }

  final steerAcceleration = 1000.0;
  final maxAcceleration = 1000.0;
  final velocity = Vector3(0, 0, -50);
  final autoDecelerate = 200;

  double walk = 0;

  void _playing(double dt) {
    if (up && worldPosition.y < maxHeight) {
      if (velocity.y < 0) velocity.y /= 1.2;
      velocity.y += steerAcceleration * dt;
    } else if (down && worldPosition.y > minHeight) {
      if (velocity.y > 0) velocity.y /= 1.2;
      velocity.y -= steerAcceleration * dt;
    } else {
      velocity.y -= velocity.y * 0.8 * autoDecelerate * dt;
    }
    if (velocity.y.abs() > maxAcceleration) {
      velocity.y = maxAcceleration * velocity.y.sign;
    }
    if (velocity.y.abs() < 0.1) velocity.y = 0;

    if (right && worldPosition.x < maxRight) {
      if (velocity.x < 0) velocity.x /= 1.2;
      velocity.x += steerAcceleration * dt;
    } else if (left && worldPosition.x > maxLeft) {
      if (velocity.x > 0) velocity.x /= 1.2;
      velocity.x -= steerAcceleration * dt;
    } else {
      velocity.x -= velocity.x * 0.8 * autoDecelerate * dt;
    }
    if (velocity.x.abs() > maxAcceleration) {
      velocity.x = maxAcceleration * velocity.x.sign;
    }
    if (velocity.x.abs() < 0.1) velocity.x = 0;

    if (worldPosition.y < minHeight) worldPosition.y = minHeight;
    if (worldPosition.y > maxHeight) worldPosition.y = maxHeight;

    final col = 1 + (worldPosition.x ~/ 50).sign;
    final row = 1 - ((worldPosition.y - midHeight) ~/ 50).sign;
    _sprite.sprite = _sheet.getSprite(row, col);

    const walkSpeed = 0.2;
    if (worldPosition.y <= minHeight + 5) {
      var idx = (walk * 6 / walkSpeed).toInt().clamp(0, 5);
      _sprite.sprite = _sheet.getSprite(3 + idx ~/ 3, idx % 3);
      walk += dt;
      if (walk > walkSpeed) walk = 0;
    }

    final opX = 0.25 + worldPosition.x.abs() / maxRight * 0.75;
    final opY = (worldPosition.y - midHeight).abs() / midHeight;
    _sprite.opacity = max(opX, opY).clamp(0, 1);
  }

  @override
  void whenDefeated() {
    final i = _sprite.sprite?.image;
    if (i == null) return;

    final pieces = sheet(i, 3 * 5, 5 * 5);
    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 5; j++) {
        final dx = (i - 2) * 10.0;
        final dy = (j - 2) * 10.0;
        parent?.add(Fragment(
          worldPosition,
          velocity,
          pieces.getSprite(9 - j, 5 + i),
          dx,
          dy,
          world: world,
        ));
      }
    }
    soundboard.play(MiniSound.explosion, volume: 0.8);
  }

  @override
  void whenHit() => shakeTime += 0.4;

  double shakeTime = 0;
}
