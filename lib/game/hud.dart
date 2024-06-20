import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:mini_harrier/core/common.dart';
import 'package:mini_harrier/core/messaging.dart';
import 'package:mini_harrier/util/bitmap_text.dart';

import '../core/soundboard.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/fonts.dart';
import 'captain.dart';

class Hud extends PositionComponent with AutoDispose, GameScriptFunctions {
  Hud(this.player);

  final Captain player;

  late SpriteSheet energy;

  final addPos = Vector2(xCenter, 20);

  double value() => player.life * 100 / player.maxLife;

  @override
  void onMount() {
    super.onMount();
    onMessage<EnemyWaveIncoming>((_) => soundboard.play(Sound.enemy_wave_incoming));
    onMessage<EnergyBoost>((_) => soundboard.play(Sound.energy_boost));
    onMessage<IncreasedFirePower>((_) => soundboard.play(Sound.increased_fire_power));
    onMessage<MissileAvailable>((_) => soundboard.play(Sound.missile_available));
    onMessage<WarningObstacles>((_) => soundboard.play(Sound.warning_obstacles));
  }

  @override
  void onLoad() async {
    priority = 100;
    add(VShmupHudMeter(value));
    fontSelect(menuFont, scale: 0.25);
    _suit = textXY('Suit Integrity', xCenter, 19, anchor: Anchor.center);
  }

  late BitmapText _suit;

  @override
  void update(double dt) {
    super.update(dt);
    if (value() == 0 && _suit.text == 'Suit Integrity') {
      _suit.removeFromParent();
      _suit = textXY('Suit Destroyed', xCenter, 19, anchor: Anchor.center);
    }
  }
}

class VShmupHudMeter extends Component with HasPaint, HasVisibility {
  VShmupHudMeter(this.value);

  final double Function() value;

  double blinkTime = 0;
  double warnTime = 2;

  @override
  void update(double dt) {
    blinkTime += dt;
    if (blinkTime > 1) blinkTime -= 1;
    isVisible = (value() > 40 || blinkTime > 0.25 ? true : false);

    var v = value();

    if (v > 0 && v <= 40) {
      warnTime += dt;
      if (warnTime > 2) {
        warnTime -= 2;
        soundboard.play(Sound.warning, volume: 0.3);
      }
    }

    // set paint color to reg, orange, yellow, green based on value():
    paint.color = switch (v) {
      > 80 => Colors.green,
      > 60 => Colors.yellow,
      > 40 => Colors.orange,
      _ => Colors.red,
    };

    if (v == 0) v = 100;
    if (v != currentRect.width) {
      currentRect = RRect.fromLTRBR(xCenter - 50, 5, xCenter - 50 + value(), 15, const Radius.circular(5));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(baseRect, basePaint);
    canvas.drawRRect(currentRect, paint);
  }

  var currentRect = RRect.fromLTRBR(xCenter - 50, 5, xCenter + 50, 15, const Radius.circular(5));
  final baseRect = RRect.fromLTRBR(xCenter - 51, 4, xCenter + 51, 16, const Radius.circular(5));
  final basePaint = Paint()..color = const Color(0x80000000);
}
