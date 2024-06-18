import '../core/mini_3d.dart';
import '../core/mini_messaging.dart';
import '../scripting/mini_script.dart';
import 'ufo_enemy.dart';

class UfoEnemies extends MiniScriptComponent {
  UfoEnemies([this.waveSize = 8, this.spawnInterval = 4.0]);

  final int waveSize;
  final double spawnInterval;

  late var remainingEnemies = waveSize;
  late var nextSpawnTime = spawnInterval;

  @override
  void update(double dt) {
    super.update(dt);
    if (remainingEnemies == 0) {
      return;
    } else if (nextSpawnTime <= 0) {
      parent!.add(UfoEnemy(_onDefeated, world: world));
      nextSpawnTime = spawnInterval;
      remainingEnemies--;
    } else {
      nextSpawnTime -= dt;
    }
  }

  var defeatedEnemies = 0;

  void _onDefeated() {
    defeatedEnemies++;
    if (defeatedEnemies == waveSize) sendMessage(EnemiesDefeated());
  }
}
