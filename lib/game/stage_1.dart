import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/checkerboard.dart';
import '../components/mountains.dart';
import '../components/sky.dart';
import '../core/common.dart';
import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../core/soundboard.dart';
import '../input/mini_shortcuts.dart';
import '../scripting/game_script.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'auto_shadows.dart';
import 'captain.dart';
import 'captain_cam.dart';
import 'effects.dart';
import 'enemy_energy_balls.dart';
import 'hud.dart';
import 'ufo_enemies.dart';
import 'ufo_enemy.dart';

class Stage1 extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onLoad() async {
    super.onLoad();

    // backgroundMusic('revenge_of_the_captain_coder.ogg');

    add(fadeIn(RectangleComponent(size: gameSize, paint: Paint()..color = const Color(0xFFa0c0ff))..priority = -10000));
    add(fadeIn(Sky()));
    add(fadeIn(Checkerboard()));
    add(fadeIn(Mountains()));
    add(fadeIn(AutoShadows()));

    effects();

    final captain = Captain(world: world);

    add(fadeIn(captain));

    final camera = added(CaptainCam());
    camera.follow = captain;
    add(Hud(captain));

    debugXY(() => 'Captain VX: ${captain.velocity.x}', 0, gameHeight - debugHeight, Anchor.bottomLeft);
    debugXY(() => 'Captain VY: ${captain.velocity.y}', 0, gameHeight, Anchor.bottomLeft);

    add(EnemyEnergyBalls(
      this,
      () => children.whereType<UfoEnemy>().where((it) => it.readyToAttack),
      captain,
    ));

    add(UfoEnemies(captain));

    onMessage<EnemiesDefeated>((_) => showScreen(Screen.title));

    soundboard.play(Sound.game_on);

    fontSelect(fancyFont, scale: 1.0);
    at(0.0, () => fadeIn(textXY('STAGE 1', xCenter, yCenter - lineHeight, scale: 2)));
    at(0.0, () => fadeIn(textXY('Did I sign up for THIS?', xCenter, yCenter + lineHeight, scale: 1)));
    at(2.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => captain.state = CaptainState.playing);
  }
}
