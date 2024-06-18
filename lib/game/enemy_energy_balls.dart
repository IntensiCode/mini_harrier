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
  EnemyEnergyBalls(this.container, this.enemies);

  final Component container;
  final Iterable<Component3D> Function() enemies;

  late final SpriteAnimation anim;

  @override
  onLoad() async => anim = await energyBalls16();

  @override
  update(double dt) {
    super.update(dt);

    if (_coolDown > 0) _coolDown -= dt;
    if (_coolDown <= 0) {
      final it = _pool.isEmpty ? EnergyBall(_recycle, world: world) : _pool.removeLast();
      it.visual.animation = anim;
      final candidates = enemies().toList();
      if (candidates.isNotEmpty) {
        final enemy = candidates.random(random);
        it.reset(enemy);
        container.add(it);
        soundboard.play(MiniSound.shot);
        _coolDown = 0.1 + random.nextDoubleLimit(0.4);
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

  void reset(Component3D source) {
    this.source = source;

    worldPosition.setFrom(source.worldPosition);
    worldPosition.z += 5;
    _lifetime = 0;

    var dx = random.nextDoubleLimit(50);
    if (worldPosition.x > 0) dx *= -1;
    var dy = 100 + random.nextDoubleLimit(100);
    if (worldPosition.y > 100) dy *= -1;

    velocity.setValues(dx, dy, -250);
  }

  final velocity = Vector3(0, 0, 0);
  double _lifetime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    worldPosition.add(velocity * dt);
    _lifetime += dt;
    if (_lifetime > 10) {
      _recycle(this);
    } else if (worldPosition.y < 0) {
      final c3d = Component3D(world: world);
      c3d.worldPosition.setFrom(worldPosition);
      final v = Vector3.zero();
      v.z = velocity.z;
      spawnEffect(MiniEffectKind.smoke, c3d, velocity: v);
      _recycle(this);
    }

    final check = parent?.children.whereType<MiniTarget>();
    if (check == null) return;

    for (final it in check) {
      if (it == source) continue;
      if (it case Component3D c3d) {
        final dist = c3d.distanceSquared3D(this);
        if (dist < 2000 && (c3d.worldPosition.z - worldPosition.z).abs() < 5) {
          it.applyDamage(plasma: 1 + state.charge * 0.5);
          _recycle(this);
          break;
        }
      }
    }
  }
}
