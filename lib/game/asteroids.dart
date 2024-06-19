import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';

const _frameSize = 256.0;

const _rotateBaseSeconds = 3.0;
const _rotateVariance = 3.0;

const _baseSpeed = 200;
const _speedVariance = 8.0;

Asteroids? _instance;

extension ScriptFunctionsExtension on MiniScriptFunctions {
  Asteroids asteroids() {
    _instance ??= Asteroids();
    if (_instance?.isMounted == true) _instance?.removeFromParent();
    return added(_instance!);
  }
}

class Asteroids extends AutoDisposeComponent with MiniScriptFunctions {
  late FragmentProgram program;
  late FragmentShader shader;

  int maxAsteroids = 16;

  double lastEmission = 0;

  @override
  void onLoad() async {
    program = await FragmentProgram.fromAsset('assets/shaders/asteroid.frag');
    shader = program.fragmentShader();
  }

  @override
  void update(double dt) {
    super.update(dt);
    lastEmission += dt;
    const minReleaseInterval = 1; //  / sqrt(maxAsteroids);
    final c = parent!.children.whereType<SideAsteroid>();
    if (c.length < maxAsteroids && lastEmission >= minReleaseInterval) {
      parent!.add(SideAsteroid(shader, _onReset, world: world));
      lastEmission = 0;
    }
  }

  void _onReset(SideAsteroid it) {
    if (children.length > maxAsteroids) {
      it.removeFromParent();
    } else {
      it.reset();
    }
  }
}

class SideAsteroid extends Component3D with HasPaint {
  final FragmentShader shader;

  late CircleHitbox hitbox;

  late bool xFlipped;
  late Color color1;
  late Color color2;
  late Color color3;
  late double dx;
  late double dy;
  late double rotationSeconds;
  late double shaderSizeFactor;
  late double shaderSeed;

  final void Function(SideAsteroid) _onReset;

  SideAsteroid(this.shader, this._onReset, {required super.world}) {
    paint.shader = shader;

    shader.setFloat(0, _frameSize); // w
    shader.setFloat(1, _frameSize); // h
    shader.setFloat(2, _frameSize); // pixels
    shader.setFloat(18, 1); // should_dither

    anchor = Anchor.center;
    size.setAll(_frameSize.toDouble());

    // add(DebugCircleHitbox(radius: 20, anchor: Anchor.center));
    hitbox = added(CircleHitbox(radius: 20, anchor: Anchor.center));

    reset();
  }

  _pickFlipped() => xFlipped = random.nextBool();

  _pickScale() => scale.setAll(0.25 + random.nextDoubleLimit(0.75));

  _pickTint() {
    final tint = Color(random.nextInt(0x20000000));
    color1 = Color.alphaBlend(tint, const Color(0xFFa3a7c2));
    color2 = Color.alphaBlend(tint, const Color(0xFF4c6885));
    color3 = Color.alphaBlend(tint, const Color(0xFF3a3f5e));
  }

  _pickPosition() {
    worldPosition.x = world.camera.x + random.nextDoubleLimit(600);
    worldPosition.y = 350 + random.nextDoubleLimit(75);
    worldPosition.z = random.nextDoublePM(25);
  }

  _pickSpeed() {
    dx = 0;
    // dx = random.nextDouble() - random.nextDouble();
    // dx *= _speedVariance;
    dy = _baseSpeed + random.nextDoubleLimit(_speedVariance);
  }

  _pickRotation() => rotationSeconds = _rotateBaseSeconds + random.nextDoubleLimit(_rotateVariance);

  _pickShaderParams() {
    shaderSizeFactor = 1.5; //+ random.nextDoubleLimit(3);
    shaderSeed = 1 + random.nextDoubleLimit(9);
  }

  reset() {
    _pickFlipped();
    _pickScale();
    _pickTint();
    _pickPosition();
    _pickSpeed();
    _pickRotation();
    _pickShaderParams();
  }

  @override
  void update(double dt) {
    super.update(dt);

    shaderTime += dt / rotationSeconds * (xFlipped ? -1 : 1);

    worldPosition.x += dt * dx;
    worldPosition.y -= dt * dy;

    bool remove = false;
    if (position.x < -_frameSize) remove = true;
    if (position.y > gameHeight + _frameSize) remove = true;
    if (remove) _onReset(this);
  }

  double shaderTime = 0;

  final rect = const Rect.fromLTWH(0, 0, _frameSize, _frameSize);

  @override
  render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..shader = shader;

    shader.setFloat(3, shaderTime);
    shader.setVec4(4, color1);
    shader.setVec4(8, color2);
    shader.setVec4(12, color3);
    shader.setFloat(16, shaderSizeFactor);
    shader.setFloat(17, shaderSeed);
    canvas.translate(-_frameSize / 2, -_frameSize / 2);
    paint.colorFilter = const ColorFilter.mode(Color(0xFF000000), BlendMode.srcATop);
    canvas.drawRect(rect, paint);

    paint.colorFilter = null;
    // omg.. fix this please :-D
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, paint);
    canvas.translate(_frameSize / 2, _frameSize / 2);
  }
}
