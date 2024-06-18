import 'package:flame/components.dart';

import '../components/delayed.dart';
import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/extensions.dart';

extension ScriptFunctionsExtension on MiniScriptFunctions {
  MiniEffects effects() => added(MiniEffects());
}

extension ComponentExtensions on Component {
  void spawnEffect(
    MiniEffectKind kind,
    Component3D anchor, {
    double? delaySeconds,
    Function()? atHalfTime,
    Vector3? velocity,
  }) {
    messaging.send(SpawnEffect(
      kind: kind,
      anchor: anchor,
      delaySeconds: delaySeconds,
      atHalfTime: atHalfTime,
      velocity: velocity,
    ));
  }
}

class MiniEffects extends MiniScriptComponent {
  late final animations = <MiniEffectKind, SpriteAnimation>{};

  @override
  void onLoad() async {
    animations[MiniEffectKind.appear] = appear();
    animations[MiniEffectKind.explosion] = await explosion32();
    animations[MiniEffectKind.hit] = hit();
    animations[MiniEffectKind.smoke] = smoke();
    animations[MiniEffectKind.sparkle] = sparkle();
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnEffect>((data) {
      final it = _pool.removeLastOrNull() ?? MiniEffect(_recycle, world: world);
      it.kind = data.kind;
      it.anim.animation = animations[data.kind]!;
      it.anim.scale = data.kind == MiniEffectKind.explosion ? Vector2.all(10.0) : Vector2.all(30.0);
      it.atHalfTime = data.atHalfTime;
      it.velocity = data.velocity;
      it.worldPosition.setFrom(data.anchor.worldPosition);
      it.worldPosition.y += 60;

      final delay = data.delaySeconds ?? 0.0;
      add(delay == 0 ? it : Delayed(delay, it));
    });
  }

  void _recycle(MiniEffect it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniEffect>[];
}

class MiniEffect extends Component3D {
  MiniEffect(this._recycle, {required super.world}) {
    anchor = Anchor.center;
    add(anim);
    add(CircleComponent(radius: 10, anchor: Anchor.center));
  }

  final anim = SpriteAnimationComponent(anchor: Anchor.center);

  final void Function(MiniEffect) _recycle;

  late MiniEffectKind kind;
  Function()? atHalfTime;
  Vector3? velocity;

  @override
  void onMount() {
    if (kind == MiniEffectKind.sparkle) {
      anim.scale.setAll(25);
    } else {
      anim.scale.setAll(10);
    }
    anim.animationTicker!.reset();
    anim.animationTicker!.onComplete = () => _recycle(this);
    if (atHalfTime != null) {
      anim.animationTicker!.onFrame = (it) {
        if (it >= anim.animation!.frames.length ~/ 2) {
          atHalfTime!();
          anim.animationTicker!.onFrame = null;
        }
      };
    }
    if (kind == MiniEffectKind.explosion) soundboard.play(MiniSound.explosion);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (velocity != null) {
      worldPosition.add(velocity! * dt);
    } else {
      worldPosition.z -= 40 * dt;
    }
  }
}
