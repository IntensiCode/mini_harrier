import 'package:mini_harrier/core/mini_3d.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import 'mini_effects.dart';
import 'mini_state.dart';

mixin MiniTarget on Component3D {
  void whenDefeated();

  double life = 3;

  /// returns true when destroyed
  bool applyDamage({double? collision, double? plasma, double? laser, double? missile}) {
    life -= (collision ?? 0) + (plasma ?? 0) + (laser ?? 0) + (missile ?? 0);
    if (life <= 0) {
      spawnEffect(MiniEffectKind.explosion, this);
      removeFromParent();
      whenDefeated();
      return true;
    } else {
      spawnEffect(MiniEffectKind.sparkle, this);
      soundboard.play(MiniSound.asteroid_clash);
      state.score++;
      return false;
    }
  }
}
