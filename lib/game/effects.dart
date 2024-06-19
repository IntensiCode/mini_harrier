import 'package:flame/components.dart';

import '../components/delayed.dart';
import '../core/common.dart';
import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../core/soundboard.dart';
import '../scripting/game_script.dart';
import '../scripting/game_script_functions.dart';
import '../util/extensions.dart';

extension ScriptFunctionsExtension on GameScriptFunctions {
  Effects effects() => added(Effects());
}

extension ComponentExtensions on Component {
  void spawnEffect(
    EffectKind kind,
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

class Effects extends GameScriptComponent {
  late final animations = <EffectKind, SpriteAnimation>{};

  @override
  void onLoad() async {
    animations[EffectKind.appear] = appear();
    animations[EffectKind.explosion] = await explosion32();
    animations[EffectKind.hit] = hit();
    animations[EffectKind.smoke] = smoke();
    animations[EffectKind.sparkle] = sparkle();
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnEffect>((data) {
      final it = _pool.removeLastOrNull() ?? Effect(_recycle, world: world);
      it.kind = data.kind;
      it.anim.animation = animations[data.kind]!;
      it.anim.scale = data.kind == EffectKind.explosion ? Vector2.all(10.0) : Vector2.all(30.0);
      it.atHalfTime = data.atHalfTime;
      it.velocity = data.velocity;
      it.worldPosition.setFrom(data.anchor.worldPosition);
      it.worldPosition.y += 60;

      final delay = data.delaySeconds ?? 0.0;
      add(delay == 0 ? it : Delayed(delay, it));
    });
  }

  void _recycle(Effect it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <Effect>[];
}

class Effect extends Component3D {
  Effect(this._recycle, {required super.world}) {
    anchor = Anchor.center;
    add(anim);
    add(CircleComponent(radius: 10, anchor: Anchor.center));
  }

  final anim = SpriteAnimationComponent(anchor: Anchor.center);

  final void Function(Effect) _recycle;

  late EffectKind kind;
  Function()? atHalfTime;
  Vector3? velocity;

  @override
  void onMount() {
    if (kind == EffectKind.sparkle) {
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
    if (kind == EffectKind.explosion) soundboard.play(Sound.explosion);
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
