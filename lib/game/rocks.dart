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
import 'damage_target.dart';
import 'fragment.dart';

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

class Rock extends Component3D with HasPaint, DamageTarget, AutoDispose, GameScriptFunctions {
  Rock(Sprite sprite, this._onReset, {required super.world}) {
    anchor = Anchor.bottomCenter;
    _sprite = added(SpriteComponent(sprite: sprite, paint: paint, anchor: Anchor.bottomCenter));
    add(CircleComponent(
      radius: 100.0,
      paint: shadow,
      anchor: Anchor.centerRight,
    )..scale.setValues(20, 0.75));
    reset();
    life = 100;
  }

  final void Function(Rock) _onReset;
  late final SpriteComponent _sprite;

  _pickScale() {
    _sprite.scale.setAll(7 + random.nextDoubleLimit(7));
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
      _sprite.opacity = fadeInTime.clamp(0.0, 1.0);
      fadeInTime += dt;
    } else if (worldPosition.z > world.camera.z - 150) {
      _sprite.opacity = ((world.camera.z - worldPosition.z) / 150).clamp(0.0, 1.0);
    } else {
      _sprite.opacity = 1;
    }

    bool remove = false;
    if (worldPosition.z > world.camera.z - 30) remove = true;
    if (position.x < -40) remove = true;
    if (position.x > gameWidth + 40) remove = true;
    if (position.y > gameHeight + 100) remove = true;
    if (remove) _onReset(this);
  }

  @override
  void whenHit() {}

  @override
  void whenDefeated() {
    final i = _sprite.sprite?.image;
    if (i == null) return;

    const cols = 5;
    const rows = 10;
    final pos = Vector3.copy(worldPosition);
    pos.y += 600;
    final pieces = sheet(i, cols, rows);
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final dx = (i - cols / 2) * 200 / cols;
        final dy = (j - rows / 2) * 600 / rows;
        parent?.add(Fragment(
          pos,
          Vector3.zero(),
          pieces.getSprite(4 - j, i),
          dx + random.nextDoublePM(200 / cols),
          dy + random.nextDoublePM(400 / rows),
          world: world,
        ));
      }
    }

    _onReset(this);
  }
}
