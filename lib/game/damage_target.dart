import 'package:mini_harrier/core/mini_3d.dart';

import '../core/common.dart';
import '../core/soundboard.dart';
import 'effects.dart';
import 'game_state.dart';

mixin DamageTarget on Component3D {
  void whenDefeated();

  void whenHit();

  double life = 3;

  /// returns true when destroyed
  bool applyDamage({double? collision, double? plasma, double? laser, double? missile}) {
    life -= (collision ?? 0) + (plasma ?? 0) + (laser ?? 0) + (missile ?? 0);
    if (life <= 0) {
      spawnEffect(EffectKind.explosion, this);
      removeFromParent();
      whenDefeated();
      return true;
    } else {
      whenHit();
      spawnEffect(EffectKind.sparkle, this);
      soundboard.play(Sound.asteroid_clash);
      state.score++;
      return false;
    }
  }
}