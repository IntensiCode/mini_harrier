import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:mini_harrier/util/extensions.dart';

import '../core/mini_3d.dart';
import '../scripting/mini_script.dart';

class AutoShadows extends MiniScriptComponent {
  final shadows = <Component3D, Shadow>{};

  @override
  void update(double dt) {
    super.update(dt);

    final active = parent?.children.whereType<Component3D>().whereNot((it) => it is Shadow).toList();
    if (active == null) return;

    final gone = shadows.keys.where((it) => !active.contains(it)).toList();
    for (final child in gone) {
      final shadow = shadows.remove(child);
      if (shadow != null) {
        shadow.removeFromParent();
        pool.add(shadow);
      }
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

class Shadow extends Component3D {
  Shadow({required super.world}) {
    add(CircleComponent(radius: 20, anchor: Anchor.center, paint: Paint()..color = const Color(0x80000000))
      ..scale.setValues(5, 2));
  }

  late Component3D _source;

  set source(Component3D value) {
    _source = value;
    scale.setFrom(value.size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    worldPosition.x = _source.worldPosition.x;
    worldPosition.y = 0;
    worldPosition.z = _source.worldPosition.z;
  }
}
