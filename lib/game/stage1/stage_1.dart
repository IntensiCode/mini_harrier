import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../components/checkerboard.dart';
import '../../components/mountains.dart';
import '../../components/sky.dart';
import '../../core/common.dart';
import '../../core/messaging.dart';
import '../../core/mini_3d.dart';
import '../../core/soundboard.dart';
import '../../input/mini_shortcuts.dart';
import '../../scripting/game_script.dart';
import '../../util/bitmap_text.dart';
import '../../util/extensions.dart';
import '../../util/fonts.dart';
import '../auto_shadows.dart';
import '../captain.dart';
import '../captain_cam.dart';
import '../effects.dart';
import '../enemy_energy_balls.dart';
import '../extras.dart';
import '../hud.dart';
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

    debugXY(() => 'Difficulty: $difficulty', 0, gameHeight - debugHeight * 2, Anchor.bottomLeft);
    debugXY(() => 'Captain VX: ${captain.velocity.x}', 0, gameHeight - debugHeight, Anchor.bottomLeft);
    debugXY(() => 'Captain VY: ${captain.velocity.y}', 0, gameHeight, Anchor.bottomLeft);

    add(EnemyEnergyBalls(
      this,
      () => children.whereType<UfoEnemy>().where((it) => it.readyToAttack),
      captain,
    ));

    soundboard.play(Sound.game_on);

    fontSelect(fancyFont, scale: 1.0);
    at(0.0, () => fadeIn(textXY('STAGE 1', xCenter, yCenter, scale: 2)));
    at(2.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => captain.state = CaptainState.playing);
    at(0.0, () => nextWave());

    onMessage<CaptainDefeated>((_) {
      clearScript();
      difficulty *= 0.8;
      at(0.5, () => fadeIn(textXY('GAME OVER', xCenter, yCenter - lineHeight * 2, scale: 2)));
      at(0.0, () => fadeIn(textXY('PRESS FIRE TO TRY AGAIN', xCenter, yCenter, scale: 1)));
      at(0.0, () => fadeIn(textXY('PRESS ESCAPE TO QUIT', xCenter, yCenter + lineHeight, scale: 1)));
      at(1.0, () => pressFireToStart());
      at(0.0, () => onKey('<Space>', () => showScreen(Screen.stage1)));
      at(0.0, () => onKey('<Escape>', () => showScreen(Screen.title)));
      executeScript();
    });

    onMessage<EnemiesDefeated>((it) {
      if (it.percent >= 0 && it.percent < 25) {
        difficulty *= 0.8;
      } else if (it.percent > 75) {
        difficulty *= 1.2;
      }

      if (_waves.isEmpty) {
        clearScript();
        at(0.5, () => fadeIn(textXY('STAGE COMPLETE', xCenter, yCenter, scale: 2)));
        at(0.0, () => sendMessage(StageComplete()));
        at(1.0, () => pressFireToStart());
        at(0.0, () => onKey('<Space>', _leave));
        executeScript();
      } else {
        switch (_waves[0]) {
          case _EnemyWaves.kamikaze:
            const subs = 'Kamikaze UFOs? Seriously?!';
            subtitles(subs, 3, image: 'dialog-captain.png', audio: 'captain-kamikaze.mp3');
            add(KamikazeUfoEnemies(captain));
            sendMessage(EnemyWaveIncoming());
          case _EnemyWaves.ufos:
            add(UfoEnemies(captain));
            sendMessage(EnemyWaveIncoming());
          case _EnemyWaves.obstacles:
            const subs = 'So... That\'s the only way forward? Really?!?';
            subtitles(subs, 3, image: 'dialog-captain.png', audio: 'captain-only-way.mp3');
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

  void _leave() {
    fadeOutAll();
    clearScript();
    at(1.0, () => showScreen(Screen.stage2));
    executeScript();
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

    sendMessage(EnemiesDefeated(-1));
  }

  final _waves = [_EnemyWaves.kamikaze, _EnemyWaves.ufos, _EnemyWaves.obstacles];
}

enum _EnemyWaves {
  kamikaze,
  ufos,
  obstacles,
}
