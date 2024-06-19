import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/messaging.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on MiniScriptFunctions {
  Extras extras(int level) => added(Extras(level));
}

extension ComponentExtensions on Component {
  void spawnExtra(Vector2 position, [Set<ExtraKind>? which]) => messaging.send(SpawnExtra(position, which));
}

class Extras extends MiniScriptComponent {
  Extras(this.level);

  final int level;

  bool get hasActiveItems => children.isNotEmpty;

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnExtra>((it) {
      final which = it.kind?.toList() ?? ExtraKind.values;
      final dist = which.fold(<(double, ExtraKind)>[], (acc, kind) {
        acc.add(((acc.lastOrNull?.$1 ?? 0) + kind.probability, kind));
        return acc;
      });
      final pick = random.nextDoubleLimit(dist.last.$1);
      dist.removeWhere((it) => it.$1 <= pick);
      final picked = dist.firstOrNull;
      if (picked != null) _spawn(it.position, picked.$2);
    });
  }

  void _spawn(Vector2 position, ExtraKind kind) {
    final it = _pool.removeLastOrNull() ?? SpawnedExtra(_recycle);
    it.sprite.sprite = sprites.getSprite(5, 3 + kind.column);
    it.kind = kind;
    it.speed = (50 + level * 0.25).clamp(50.0, 100.0);
    it.position.setFrom(position);
    add(it);
  }

  void _recycle(SpawnedExtra it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <SpawnedExtra>[];
}

class SpawnedExtra extends PositionComponent with CollisionCallbacks {
  SpawnedExtra(this._recycle) {
    anchor = Anchor.center;
    add(sprite = SpriteComponent(anchor: Anchor.center));
    add(debug = DebugCircleHitbox(radius: 6, anchor: Anchor.center));
    add(hitbox = CircleHitbox(radius: 6, anchor: Anchor.center));
  }

  final void Function(SpawnedExtra it) _recycle;

  late SpriteComponent sprite;
  late DebugCircleHitbox debug;
  late CircleHitbox hitbox;
  late ExtraKind kind;
  late double speed;

  @override
  void onMount() {
    super.onMount();
    final radius = kind.name.startsWith('score') ? 4.0 : 6.0;
    hitbox.radius = radius;
    debug.radius = radius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameHeight + size.y) _recycle(this);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case Collector it) {
      // spawnEffect(MiniEffectKind.sparkle, other.position);
      it.collect(kind);
      _recycle(this);
    }
  }
}
