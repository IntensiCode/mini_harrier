import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../scripting/mini_script.dart';
import '../util/extensions.dart';
import 'effects.dart';
import 'enemy_energy_balls.dart';
import 'fragment.dart';
import 'swirl_weapon.dart';

class AutoShadows extends MiniScriptComponent {
  final shadows = <Component3D, Shadow>{};

  @override
  void update(double dt) {
    super.update(dt);

    final active = parent?.children
        .whereType<Component3D>() //
        .whereNot((it) => it is Shadow) //
        .whereNot((it) => it is Effect)
        .toList();

    if (active == null) return;

    final gone = shadows.keys.where((it) => !active.contains(it)).toList();
    for (final it in shadows.entries) {
      if (it.value.removeMe) gone.add(it.key);
    }
    for (final child in gone) {
      final shadow = shadows.remove(child);
      if (shadow == null) continue;
      shadow.removeFromParent();
      pool.add(shadow);
    }

    final add = active.where((it) => !shadows.containsKey(it)).toList();
    for (final child in add) {
      final shadow = pool.removeLastOrNull() ?? Shadow(world: world);
      shadow.source = child;
      shadows[child] = shadow;
      parent?.add(shadow);
    }
  }

  final pool = <Shadow>[];
}

class Shadow extends Component3D with HasVisibility {
  Shadow({required super.world}) {
    it = added(CircleComponent(radius: 20, anchor: Anchor.center, paint: Paint()..color = const Color(0x80000000)));
    it.scale.setValues(5, 2);
  }

  late final CircleComponent it;

  Component3D? _source;

  set source(Component3D value) {
    removeMe = false;
    _source = value;
    if (_source is Fragment) {
      it.scale.setValues(1, 0.5);
    } else if (_source is EnergyBall || _source is SwirlProjectile) {
      it.scale.setValues(3, 1.5);
    } else {
      it.scale.setValues(5, 2);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final it = _source;
    if (it == null) return;

    worldPosition.x = it.worldPosition.x - it.worldPosition.y / 2;
    worldPosition.y = 0;
    worldPosition.z = it.worldPosition.z;

    if (position.x < -50) removeMe = true;
    if (position.x > gameWidth + 50) removeMe = true;
    if (position.y > gameHeight + 50) removeMe = true;
    if (it.worldPosition.z < world.camera.z - 2000) removeMe = true;
    if (it.worldPosition.z > world.camera.z - 30) removeMe = true;
    if (it.isMounted == false) removeMe = true;
    if (removeMe) _source = null;

    isVisible = it.worldPosition.y > 0 && position.y > 100;
  }

  @override
  render(Canvas canvas) {
    if (removeMe || _source == null) return;
    super.render(canvas);
  }

  bool removeMe = false;
}
