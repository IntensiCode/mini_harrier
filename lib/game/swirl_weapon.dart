import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'damage_target.dart';
import 'game_state.dart';

class SwirlWeapon extends Component with AutoDispose, MiniScriptFunctions {
  SwirlWeapon(this.captain, this.shouldFire, this.world, this.world3d);

  final Component3D captain;
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
      it.reset(captain.worldPosition);
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
    worldPosition.y += 55;
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

    final check = parent?.children.whereType<DamageTarget>();
    if (check == null) return;

    for (final it in check) {
      if ((it.worldPosition.x - worldPosition.x).abs() > 55) continue;
      if ((it.worldPosition.z - worldPosition.z).abs() > 5) continue;
      if ((it.worldPosition.y + 75 - worldPosition.y).abs() > 50) continue;
      it.applyDamage(plasma: 1 + state.charge * 0.5);
      _recycle(this);
      break;
    }
  }
}
