import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'mini_effects.dart';
import 'mini_state.dart';
import 'mini_target.dart';

class EnemyEnergyBalls extends Component with AutoDispose, MiniScriptFunctions {
  EnemyEnergyBalls(this.container, this.enemies, this.captain);

  final Component container;
  final Iterable<Component3D> Function() enemies;
  final Component3D captain;

  late final SpriteAnimation anim;

  @override
  onLoad() async => anim = await energyBalls16();

  @override
  update(double dt) {
    super.update(dt);

    if (captain.isMounted == false) return;

    if (_coolDown > 0) _coolDown -= dt;
    if (_coolDown <= 0) {
      final it = _pool.isEmpty ? EnergyBall(_recycle, world: world) : _pool.removeLast();
      it.visual.animation = anim;
      final candidates = enemies().toList();
      if (candidates.isNotEmpty) {
        final enemy = candidates.random(random);
        it.reset(enemy, captain);
        container.add(it);
        soundboard.play(MiniSound.shot);
        _coolDown = 0.4 + random.nextDoubleLimit(0.4) - candidates.length * 0.05;
      }
    }
  }

  void _recycle(EnergyBall it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <EnergyBall>[];

  double _coolDown = 0;
}

class EnergyBall extends Component3D {
  EnergyBall(this._recycle, {required super.world}) {
    add(RectangleHitbox(position: Vector2.zero(), size: Vector2.all(10), anchor: Anchor.center));
    add(visual = SpriteAnimationComponent(anchor: Anchor.center)..scale.setAll(10));
  }

  final void Function(EnergyBall) _recycle;

  late final SpriteAnimationComponent visual;

  late Component3D source;

  void reset(Component3D source, Component3D target) {
    this.source = source;

    worldPosition.setFrom(source.worldPosition);
    worldPosition.y += 50;
    worldPosition.z += 5;
    _lifetime = 0;

    velocity.setFrom(target.worldPosition);
    velocity.sub(worldPosition);
    velocity.normalize();
    velocity.scale(250);

    velocity.x += random.nextDoublePM(10) - 5;
    velocity.y += random.nextDoublePM(10) - 5;
  }

  final velocity = Vector3(0, 0, 0);
  double _lifetime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    worldPosition.add(velocity * dt);
    _lifetime += dt;
    if (_lifetime > 5) {
      _recycle(this);
    } else if (worldPosition.y < 0) {
      worldPosition.y = 0;
      final c3d = Component3D(world: world);
      c3d.worldPosition.setFrom(worldPosition);
      final v = Vector3.zero();
      v.z = velocity.z;
      spawnEffect(MiniEffectKind.smoke, c3d, velocity: v);
      _recycle(this);
      return;
    }

    if (position.x < -20 || position.x > gameWidth + 20) {
      _recycle(this);
      return;
    }
    if (position.y < -20 || position.y > gameHeight + 20) {
      _recycle(this);
      return;
    }

    if (worldPosition.z > world.camera.z - 10) {
      _recycle(this);
      return;
    }

    final check = parent?.children.whereType<MiniTarget>();
    if (check == null) return;

    for (final it in check) {
      if (it == source) continue;
      if ((it.worldPosition.x - worldPosition.x).abs() > 30) continue;
      if ((it.worldPosition.z - worldPosition.z).abs() > 5) continue;
      if ((it.worldPosition.y + 25 - worldPosition.y).abs() > 40) continue;
      it.applyDamage(plasma: 1 + state.charge * 0.5);
      _recycle(this);
      return;
    }
  }
}
