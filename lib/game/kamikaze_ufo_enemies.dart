import 'package:dart_minilog/dart_minilog.dart';

import '../core/common.dart';
import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../scripting/game_script.dart';
import 'kamikaze_ufo_enemy.dart';
import 'ufo_enemy.dart';

class KamikazeUfoEnemies extends GameScriptComponent {
  KamikazeUfoEnemies(this.captain) {
    waveSize = (8 * difficulty).toInt();
    spawnInterval = 1.0 * (1 / difficulty);
    logInfo('wave size: $waveSize, spawn interval: $spawnInterval');
  }

  final Component3D captain;
  late final int waveSize;
  late final double spawnInterval;

  late var remainingEnemies = waveSize;
  late var nextSpawnTime = spawnInterval;

  @override
  void update(double dt) {
    super.update(dt);
    if (captain.isMounted == false) {
      parent?.children.whereType<UfoEnemy>().forEach((it) => it.flyOff());
      removeFromParent();
      return;
    }
    if (remainingEnemies == 0) {
      return;
    } else if (nextSpawnTime <= 0) {
      parent!.add(KamikazeUfoEnemy(_onDefeated, captain, world: world));
      nextSpawnTime = spawnInterval;
      remainingEnemies--;
    } else {
      nextSpawnTime -= dt;
    }
  }

  var defeatedEnemies = 0;
  var destroyedEnemies = 0;

  void _onDefeated(bool destroyed) {
    defeatedEnemies++;
    if (destroyed) destroyedEnemies++;
    if (defeatedEnemies == waveSize) {
      sendMessage(EnemiesDefeated(destroyedEnemies * 100 ~/ defeatedEnemies));
      removeFromParent();
    }
  }
}
