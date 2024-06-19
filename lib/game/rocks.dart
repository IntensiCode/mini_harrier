import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../core/soundboard.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';

Rocks? _instance;

extension ScriptFunctionsExtension on GameScriptFunctions {
  Rocks rocks() {
    _instance ??= Rocks();
    if (_instance?.isMounted == true) _instance?.removeFromParent();
    return added(_instance!);
  }
}

class Rocks extends AutoDisposeComponent with GameScriptFunctions {
  int maxBushes = 16;

  double lastEmission = 0;

  late final Sprite bush;

  @override
  void onMount() {
    super.onMount();
    soundboard.play(Sound.warning_obstacles);
  }

  @override
  void onLoad() async => bush = await game.loadSprite('rock.png');

  int remaining = 50;

  @override
  void update(double dt) {
    super.update(dt);
    if (remaining == 0) {
      final c = parent?.children.whereType<Rock>().length;
      if (c == 0) {
        removeFromParent();
        sendMessage(EnemiesDefeated());
      }
      return;
    }

    lastEmission += dt;
    const minReleaseInterval = 0.5; //  / sqrt(maxBushes);
    final c = parent!.children.whereType<Rock>();
    if (c.length < maxBushes && lastEmission >= minReleaseInterval) {
      parent!.add(Rock(bush, _onReset, world: world));
      lastEmission = 0;
      remaining--;
    }
  }

  void _onReset(Rock it) {
    if (children.length > maxBushes || remaining == 0) {
      it.removeFromParent();
    } else {
      it.reset();
      remaining--;
    }
  }
}

final shadow = Paint()..color = const Color(0x80000000);

class Rock extends Component3D with HasPaint {
  Rock(this.bush, this._onReset, {required super.world}) {
    anchor = Anchor.bottomCenter;
    sprite = added(SpriteComponent(sprite: bush, paint: paint, anchor: Anchor.bottomCenter));
    add(CircleComponent(
      radius: 100.0,
      paint: shadow,
      anchor: Anchor.centerRight,
    )..scale.setValues(20, 0.75));
    reset();
  }

  final Sprite bush;
  final void Function(Rock) _onReset;
  late final SpriteComponent sprite;

  _pickScale() {
    sprite.scale.setAll(7 + random.nextDoubleLimit(7));
  }

  static double lastX = 0;

  _pickPosition() {
    final off = random.nextDoublePM(2500);
    worldPosition.x = world.camera.x + off;
    if ((lastX - worldPosition.x).abs() < 500) {
      if (lastX < 0) {
        final off = random.nextDoubleLimit(2500);
        worldPosition.x = world.camera.x + off;
      } else {
        final off = random.nextDoubleLimit(2500);
        worldPosition.x = world.camera.x - off;
      }
    }
    worldPosition.y = 0.0;
    worldPosition.z = world.camera.z - 4000;
    lastX = worldPosition.x;
  }

  reset() {
    _pickScale();
    _pickPosition();
  }

  double fadeInTime = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (fadeInTime < 1.0) {
      sprite.opacity = fadeInTime.clamp(0.0, 1.0);
      fadeInTime += dt;
    } else if (worldPosition.z > world.camera.z - 150) {
      sprite.opacity = ((world.camera.z - worldPosition.z) / 150).clamp(0.0, 1.0);
    } else {
      sprite.opacity = 1;
    }

    bool remove = false;
    if (worldPosition.z > world.camera.z - 30) remove = true;
    if (position.x < -40) remove = true;
    if (position.x > gameWidth + 40) remove = true;
    if (position.y > gameHeight + 100) remove = true;
    if (remove) _onReset(this);
  }
}
