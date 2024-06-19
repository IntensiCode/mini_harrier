import 'package:flame/components.dart';
import 'package:mini_harrier/core/mini_3d.dart';
import 'package:mini_harrier/game/effects.dart';

import '../core/common.dart';
import '../core/messaging.dart';
import '../scripting/game_script.dart';
import '../scripting/game_script_functions.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on GameScriptFunctions {
  Extras extras() => added(Extras());
}

extension ComponentExtensions on Component {
  void spawnExtra(Vector3 position, [Set<ExtraKind>? which]) => messaging.send(SpawnExtra(position, which));
}

class Extras extends GameScriptComponent {
  bool get hasActiveItems => children.isNotEmpty;

  late final animations = <ExtraKind, SpriteAnimation>{};

  @override
  void onLoad() async {
    final sheet = await sheetIWH('extras_alt.png', 32, 16);
    const stepTime = 0.05;
    animations[ExtraKind.energy] = sheet.createAnimation(row: 0, stepTime: stepTime);
    animations[ExtraKind.laserCharge] = sheet.createAnimation(row: 1, stepTime: stepTime);
    animations[ExtraKind.missile] = sheet.createAnimation(row: 2, stepTime: stepTime);
  }

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

  void _spawn(Vector3 position, ExtraKind kind) {
    final it = _pool.removeLastOrNull() ?? SpawnedExtra(_recycle, world: world);
    it.anim.animation = animations[kind]!;
    it.kind = kind;
    it.worldPosition.setFrom(position);
    it.reset();
    parent?.add(it);
  }

  void _recycle(SpawnedExtra it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <SpawnedExtra>[];
}

class SpawnedExtra extends Component3D {
  SpawnedExtra(this._recycle, {required super.world}) {
    anchor = Anchor.center;
    add(anim = SpriteAnimationComponent(anchor: Anchor.center));
    anim.scale.setAll(10);
  }

  reset() {
    lifetime = 10;
    velocity.setZero();
  }

  final void Function(SpawnedExtra it) _recycle;

  late SpriteAnimationComponent anim;
  late ExtraKind kind;

  double lifetime = 10;

  final velocity = Vector3.zero();

  @override
  void update(double dt) {
    super.update(dt);
    lifetime -= dt;
    if (lifetime <= 0) {
      _expire();
      return;
    }
    worldPosition.z += 10 * dt;
    if (worldPosition.y > 5) {
      velocity.y -= 1000 * dt;
    }
    worldPosition.add(velocity * dt);
    if (worldPosition.y <= 5) {
      worldPosition.y = 5;
      velocity.y = -velocity.y * 0.5;
    }

    if (position.x < -20 || position.x > gameWidth + 20) {
      _expire();
      return;
    }
    if (position.y < -20 || position.y > gameHeight + 20) {
      _expire();
      return;
    }
    if (worldPosition.z > world.camera.z - 10) {
      _expire();
      return;
    }
  }

  void _expire() {
    spawnEffect(EffectKind.smoke, this);
    _recycle(this);
  }
}
