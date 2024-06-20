import 'package:dart_minilog/dart_minilog.dart';
import 'package:mini_harrier/core/common.dart';

import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../scripting/game_script.dart';
import 'ufo_enemy.dart';

class UfoEnemies extends GameScriptComponent {
  UfoEnemies(this.captain) {
    waveSize = (12 * difficulty).toInt();
    spawnInterval = 3 * (1 / difficulty);
    logInfo('wave size: $waveSize, spawn interval: $spawnInterval');
  }

  final Component3D captain;
  late final int waveSize;
  late final double spawnInterval;

  late var remainingEnemies = waveSize;
  late var nextSpawnTime = spawnInterval;

  double waveTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    waveTime += dt;
    if (captain.isMounted == false) {
      parent?.children.whereType<UfoEnemy>().forEach((it) => it.flyOff());
      removeFromParent();
      return;
    }
    if (remainingEnemies == 0) {
      return;
    } else if (nextSpawnTime <= 0) {
      parent!.add(UfoEnemy(_onDefeated, captain, world: world));
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
      logInfo('wave time: $waveTime seconds');
      final diff = switch (waveTime) {
        < 30 => 100,
        < 45 => 80,
        < 60 => 50,
        < 120 => 30,
        _ => 0,
      };
      sendMessage(EnemiesDefeated(diff));
      removeFromParent();
    }
  }
}
