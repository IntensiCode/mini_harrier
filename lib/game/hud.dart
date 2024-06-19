import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:mini_harrier/core/common.dart';

import '../core/mini_soundboard.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'captain.dart';

class Hud extends PositionComponent with AutoDispose, MiniScriptFunctions {
  Hud(this.player);

  final Captain player;

  late SpriteSheet energy;

  final addPos = Vector2(xCenter, 20);

  @override
  void onLoad() async {
    priority = 100;
    energy = sheet(await image('hud_meter.png'), 1, 9);
    add(VShmupHudMeter(energy, () => player.life * 100 / player.maxLife)
      ..position.setValues(xCenter, 10)
      ..anchor = Anchor.center);
  }
}

class VShmupHudMeter extends SpriteComponent with HasVisibility {
  VShmupHudMeter(this.sheet, this.value);

  final SpriteSheet sheet;
  final double Function() value;

  @override
  void onLoad() => _update();

  void _update() {
    final row = ((100 - value()) / 100 * sheet.rows).clamp(0, sheet.rows - 1).toInt();
    sprite = sheet.getSprite(row, 0);
  }

  double blinkTime = 0;
  double warnTime = 0;

  @override
  void update(double dt) {
    blinkTime += dt;
    if (blinkTime > 1) blinkTime -= 1;
    isVisible = value() > 0 && (value() > 22 || blinkTime > 0.25 ? true : false);
    if (value() == 0) return;

    if (!isVisible) {
      warnTime += dt;
      if (warnTime > 1) {
        warnTime -= 1;
        soundboard.play(MiniSound.warning);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _update();
    super.render(canvas);
  }
}
