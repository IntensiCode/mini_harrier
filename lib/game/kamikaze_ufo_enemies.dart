import '../core/messaging.dart';
import '../core/mini_3d.dart';
import '../scripting/mini_script.dart';
import 'kamikaze_ufo_enemy.dart';
import 'ufo_enemy.dart';

class KamikazeUfoEnemies extends MiniScriptComponent {
  KamikazeUfoEnemies(this.captain, [this.waveSize = 10, this.spawnInterval = 2.0]);

  final Component3D captain;
  final int waveSize;
  final double spawnInterval;

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
      parent!.add(KamikazeUfoEnemy(_onDefeated, world: world));
      nextSpawnTime = spawnInterval;
      remainingEnemies--;
    } else {
      nextSpawnTime -= dt;
    }
  }

  var defeatedEnemies = 0;

  void _onDefeated() {
    defeatedEnemies++;
    if (defeatedEnemies == waveSize) {
      sendMessage(EnemiesDefeated());
      removeFromParent();
    }
  }
}
