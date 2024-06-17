import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import '../components/checkerboard.dart';
import '../components/mountains.dart';
import '../components/sky.dart';
import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_shortcuts.dart';
import '../scripting/mini_script.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'auto_shadows.dart';
import 'captain.dart';
import 'mini_effects.dart';
import 'ufo_enemies.dart';

class Stage1 extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onLoad() async {
    super.onLoad();

    // backgroundMusic('revenge_of_the_captain_coder.ogg');

    add(fadeIn(RectangleComponent(size: gameSize, paint: Paint()..color = const Color(0xFFa0c0ff))..priority = -3000));
    add(fadeIn(Sky()));
    add(fadeIn(Checkerboard()));
    add(fadeIn(Mountains()));
    add(fadeIn(AutoShadows()));

    effects();

    final captain = Captain(world: world);

    add(fadeIn(captain));

    final camera = added(_CameraMovement());
    camera.follow = captain;

    debugXY(() => 'Captain VX: ${captain.velocity.x}', 0, gameHeight - debugHeight, Anchor.bottomLeft);
    debugXY(() => 'Captain VY: ${captain.velocity.y}', 0, gameHeight, Anchor.bottomLeft);
    add(UfoEnemies());

    soundboard.play(MiniSound.game_on);

    fontSelect(fancyFont, scale: 1.0);
    at(0.0, () => fadeIn(textXY('STAGE 1', xCenter, yCenter - lineHeight, scale: 2)));
    at(0.0, () => fadeIn(textXY('Did I sign up for THIS?', xCenter, yCenter + lineHeight, scale: 1)));
    at(2.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => captain.state = CaptainState.playing);
  }
}

class _CameraMovement extends Component {
  Captain? follow;

  final currentPosition = Vector3(0, 10, 50);

  @override
  void update(double dt) {
    super.update(dt);

    world.camera.setFrom(currentPosition);
    world.camera.z += 25;

    final f = follow;
    if (f == null) return;

    currentPosition.setFrom(f.worldPosition);
    currentPosition.x = currentPosition.x / 3;
    currentPosition.y = (currentPosition.y - midHeight) / 4 + midHeight;
  }
}
