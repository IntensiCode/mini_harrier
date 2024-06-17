import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import 'components/checkerboard.dart';
import 'core/mini_3d.dart';
import 'core/mini_common.dart';
import 'game/asteroids.dart';
import 'input/mini_shortcuts.dart';
import 'scripting/mini_script.dart';
import 'scripting/mini_script_functions.dart';
import 'util/auto_dispose.dart';
import 'util/bitmap_text.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

class TitleScreen extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() {
    super.onMount();
    onKey('<Space>', () => _leave());
  }

  void _leave() {
    clearScript();
    at(0.0, () => fadeOutAll());
    at(1.0, () => showScreen(Screen.intro));
    executeScript();
  }

  @override
  void onLoad() async {
    super.onLoad();

    add(fadeIn(RectangleComponent(size: gameSize, paint: Paint()..color = const Color(0xFF102060))..priority = -1000));
    add(fadeIn(Checkerboard()));
    add(_CameraMovement());
    add(Asteroids());

    fontSelect(menuFont, scale: fontScale);

    late SpriteAnimationComponent anim;

    const yCenter = gameHeight / 4;
    at(0.5, () => fadeIn(textXY('An', xCenter, yCenter - lineHeight)));
    at(1.0, () => fadeIn(textXY('IntensiCode', xCenter, yCenter)));
    at(1.0, () => fadeIn(textXY('Presentation', xCenter, yCenter + lineHeight)));
    at(2.5, () => fadeOutByType<BitmapText>());
    at(1.0, () => playAudio('swoosh.ogg'));
    at(0.1, () async {
      anim = makeAnimXY(await _loadSplashAnim(), xCenter, yCenter);
      anim.size.setValues(lineHeight * 6, lineHeight * 5);
    });
    at(0.0, () => fadeIn(textXY('A', xCenter, yCenter - lineHeight * 3)));
    at(0.0, () => fadeIn(textXY('Game', xCenter, yCenter + lineHeight * 4)));
    at(2.0, () => scaleTo(anim, 10, 1, Curves.decelerate));
    at(0.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => anim.fadeOutDeep());
    at(0.0, () => backgroundMusic('the_captain_coder.mp3'));
    at(0.0, () => add(_FloatingCaptain(world: world)));
    at(2.0, () async => fadeIn(await _loadTitle()));
    at(0.0, () => fontSelect(menuFont, scale: fontScale * 2));
    at(1.0, () => fadeIn(textXY('IN', xCenter, gameHeight / 2)..priority = -30));
    at(1.0, () async => fadeIn(await _loadSubtitle()));
    at(1.0, () async => fadeIn(await _loadFlame()));
    at(2.0, () => pressFireToStart());
  }

  Future<SpriteAnimation> _loadSplashAnim() =>
      loadAnim('splash_anim.png', frames: 13, stepTimeSeconds: 0.05, frameWidth: 120, frameHeight: 90, loop: false);

  Future<SpriteComponent> _loadTitle() async => await spriteXY('captain_title.png', xCenter, gameHeight / 4)
    ..priority = -20;

  Future<SpriteComponent> _loadSubtitle() async => await spriteXY('captain_title_name.png', xCenter, gameHeight * 6 / 8)
    ..priority = -20;

  Future<SpriteComponent> _loadFlame() async => await spriteXY('flame.png', 0, gameHeight, Anchor.bottomLeft);
}

class _CameraMovement extends Component {
  double time = 0;

  @override
  void update(double dt) {
    super.update(dt);

    time += dt;

    world.camera.x += 200 * dt;
    world.camera.y = cos(time * 1.1923) * sin(time * 2) * 10 + 50;
    world.camera.z = cos(time) * 10 + 20;
  }
}

class _FloatingCaptain extends Component3D with AutoDispose, MiniScriptFunctions {
  _FloatingCaptain({required super.world}) {
    worldPosition.x = -100;
    worldPosition.y = 50;
    worldPosition.z = 0;
  }

  @override
  onLoad() async => add(fadeIn(await spriteXY('captain.png', 0, 0)));

  double time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (time < 2) {
      final x = 130 - 150 * Curves.decelerate.transform(time / 2);
      worldPosition.x = world.camera.x + x;
      time += dt;
    } else {
      worldPosition.x = world.camera.x - 20;
    }
  }
}
