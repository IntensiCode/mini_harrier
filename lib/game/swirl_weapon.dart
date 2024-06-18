import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'mini_state.dart';
import 'mini_target.dart';

class SwirlWeapon extends Component with AutoDispose, MiniScriptFunctions {
  SwirlWeapon(this.ship, this.shouldFire, this.world, this.world3d);

  final Component3D ship;
  final bool Function() shouldFire;
  final Component world;
  final World3D world3d;

  late final SpriteAnimation anim;

  @override
  onLoad() async {
    anim = await loadAnimWH('swirl.png', 18, 18);
  }

  @override
  update(double dt) {
    super.update(dt);

    if (_coolDown > 0) _coolDown -= dt;
    if (_coolDown <= 0 && shouldFire()) {
      final it = _pool.isEmpty ? SwirlProjectile(_recycle, world: world3d) : _pool.removeLast();
      it.visual.animation = anim;
      it.reset(ship.worldPosition);
      world.add(it);
      soundboard.play(MiniSound.shot);
      _coolDown = 0.3;
    }
  }

  void _recycle(SwirlProjectile it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <SwirlProjectile>[];

  double _coolDown = 0;
}

class SwirlProjectile extends Component3D {
  SwirlProjectile(this._recycle, {required super.world}) {
    add(RectangleHitbox(position: Vector2.zero(), size: Vector2.all(10), anchor: Anchor.center));
    add(visual = SpriteAnimationComponent(anchor: Anchor.center)..scale.setAll(10));
  }

  final void Function(SwirlProjectile) _recycle;

  late final SpriteAnimationComponent visual;

  void reset(Vector3 position) {
    worldPosition.setFrom(position);
    worldPosition.x -= 5;
    worldPosition.y += 5;
    worldPosition.z -= 10;
    _lifetime = 0;
  }

  double _lifetime = 0;

  double speed = 500;

  @override
  void update(double dt) {
    super.update(dt);
    worldPosition.z -= speed * dt;
    if (speed < 1000) speed += 1000 * dt;
    _lifetime += dt;
    if (_lifetime > 5) _recycle(this);

    final check = parent?.children.whereType<MiniTarget>();
    if (check == null) return;

    for (final it in check) {
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
