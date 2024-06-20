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
import '../game/extras.dart';
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
import 'kamikaze_ufo_enemies.dart';
import 'kamikaze_ufo_enemy.dart';
import 'rocks.dart';
import 'ufo_enemies.dart';
import 'ufo_enemy.dart';

class Stage1 extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onLoad() async {
    super.onLoad();

    backgroundMusic('stage1.mp3');

    add(fadeIn(RectangleComponent(size: gameSize, paint: Paint()..color = const Color(0xFFa0c0ff))..priority = -10000));
    add(fadeIn(Sky()));
    add(fadeIn(Checkerboard()));
    add(fadeIn(Mountains()));
    add(fadeIn(AutoShadows()));

    final captain = Captain(world: world);
    add(fadeIn(captain));

    effects();
    extras(captain);

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

    soundboard.play(Sound.game_on);

    fontSelect(fancyFont, scale: 1.0);
    at(0.0, () => fadeIn(textXY('STAGE 1', xCenter, yCenter - lineHeight, scale: 2)));
    at(0.0, () => fadeIn(textXY('Did I sign up for THIS?', xCenter, yCenter + lineHeight, scale: 1)));
    at(0.0, () => playAudio('captain-did-i-sign-up-for-this.mp3'));
    at(2.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => captain.state = CaptainState.playing);
    at(0.0, () => nextWave());

    onMessage<EnemiesDefeated>((_) {
      if (_waves.isEmpty) {
        clearScript();
        at(0.0, () => fadeIn(textXY('STAGE COMPLETE', xCenter, yCenter, scale: 2)));
        at(1.0, () => pressFireToStart());
        executeScript();
      } else {
        switch (_waves[0]) {
          case _EnemyWaves.kamikaze:
            add(KamikazeUfoEnemies(captain));
            sendMessage(EnemyWaveIncoming());
          case _EnemyWaves.ufos:
            add(UfoEnemies(captain));
            sendMessage(EnemyWaveIncoming());
          case _EnemyWaves.obstacles:
            add(Rocks(captain));
            sendMessage(WarningObstacles());
        }
        _waves.removeAt(0);
      }
    });

    if (debug.value) {
      onKey('<C-n>', () => nextWave());
      onKey('<C-p>', () => add(KamikazeUfoEnemies(captain)));
      onKey('<C-o>', () => add(UfoEnemies(captain)));
      onKey('<C-r>', () => add(Rocks(captain)));
    }
  }

  void nextWave() {
    children
        .where((it) =>
            it is KamikazeUfoEnemies ||
            it is KamikazeUfoEnemy ||
            it is UfoEnemies ||
            it is UfoEnemy ||
            it is Rocks ||
            it is Rock)
        .forEach((it) => it.removeFromParent());

    sendMessage(EnemiesDefeated());
  }

  final _waves = [_EnemyWaves.kamikaze, _EnemyWaves.ufos, _EnemyWaves.obstacles];
}

enum _EnemyWaves {
  kamikaze,
  ufos,
  obstacles,
}
