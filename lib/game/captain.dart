import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../input/mini_game_keys.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'swirl_weapon.dart';

enum CaptainState {
  defeated,
  intro,
  playing,
}

class Captain extends Component3D with AutoDispose, MiniScriptFunctions, KeyboardHandler, MiniGameKeys {
  Captain({required super.world}) {
    worldPosition.x = 0;
    worldPosition.y = 50;
    worldPosition.z = 25;
  }

  late final weapon = SwirlWeapon(this, () => primaryFire, parent!, world);

  late CaptainState state = CaptainState.intro;

  late final SpriteSheet _sheet;
  late final SpriteComponent _sprite;

  @override
  onLoad() async {
    _sheet = sheet(await image('captain_sprite.png'), 3, 3);
    _sprite = spriteSXY(_sheet.getSprite(1, 1), 0, 0);
    _sprite.scale.setAll(2);
    add(fadeIn(_sprite));
    add(weapon);
  }

  @override
  void update(double dt) {
    super.update(dt);
    worldPosition.add(velocity * dt);
    if (state == CaptainState.playing) _playing(dt);
  }

  final steerAcceleration = 1000.0;
  final maxAcceleration = 1000.0;
  final velocity = Vector3(0, 0, -500);
  final autoDecelerate = 200;

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

    final opX = 0.25 + worldPosition.x.abs() / maxRight * 0.75;
    final opY = (worldPosition.y - midHeight).abs() / midHeight;
    _sprite.opacity = max(opX, opY).clamp(0, 1);
  }
}
