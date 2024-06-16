import 'package:flame/components.dart';
import 'package:mini_harrier/core/mini_3d.dart';

import '../components/delayed.dart';
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
  void spawnEffect(MiniEffectKind kind, Component3D anchor, {double? delaySeconds, Function()? atHalfTime}) =>
      messaging.send(SpawnEffect(kind, anchor, delaySeconds, atHalfTime));
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
      it.worldPosition.setFrom(data.anchor.worldPosition);
      // it.velocity.setFrom(data.anchor.velocity);
      it.atHalfTime = data.atHalfTime;

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

  final anim = SpriteAnimationComponent(anchor: Anchor.center)..scale.setAll(10);

  final void Function(MiniEffect) _recycle;

  late MiniEffectKind kind;
  Function()? atHalfTime;

  @override
  void onMount() {
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
    worldPosition.z -= 400 * dt;
  }
}
