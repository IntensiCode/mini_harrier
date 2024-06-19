import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';

Rocks? _instance;

extension ScriptFunctionsExtension on MiniScriptFunctions {
  Rocks rocks() {
    _instance ??= Rocks();
    if (_instance?.isMounted == true) _instance?.removeFromParent();
    return added(_instance!);
  }
}

class Rocks extends AutoDisposeComponent with MiniScriptFunctions {
  int maxBushes = 16;

  double lastEmission = 0;

  late final Sprite bush;

  @override
  void onLoad() async => bush = await game.loadSprite('rock.png');

  @override
  void update(double dt) {
    super.update(dt);
    lastEmission += dt;
    const minReleaseInterval = 1; //  / sqrt(maxBushes);
    final c = parent!.children.whereType<Rock>();
    if (c.length < maxBushes && lastEmission >= minReleaseInterval) {
      parent!.add(Rock(bush, _onReset, world: world));
      lastEmission = 0;
    }
  }

  void _onReset(Rock it) {
    if (children.length > maxBushes) {
      it.removeFromParent();
    } else {
      it.reset();
    }
  }
}

class Rock extends Component3D with HasPaint {
  Rock(this.bush, this._onReset, {required super.world}) {
    anchor = Anchor.bottomCenter;
    sprite = added(SpriteComponent(sprite: bush, paint: paint, anchor: Anchor.bottomCenter));
    reset();
  }

  final Sprite bush;
  final void Function(Rock) _onReset;
  late final SpriteComponent sprite;

  _pickScale() => scale.setAll(3 + random.nextDoubleLimit(3));

  _pickPosition() {
    final off = random.nextDoublePM(1000);
    worldPosition.x = world.camera.x + off;
    worldPosition.y = 0;
    worldPosition.z = world.camera.z - 5000;
  }

  reset() {
    _pickScale();
    _pickPosition();
  }

  @override
  void update(double dt) {
    super.update(dt);

    bool remove = false;
    if (worldPosition.z > world.camera.z - 50) remove = true;
    if (position.x < -10) remove = true;
    if (position.x > gameWidth + 10) remove = true;
    if (position.y > gameHeight + 20) remove = true;
    if (remove) _onReset(this);
  }
}
