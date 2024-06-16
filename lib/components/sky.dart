import 'dart:ui';

import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';

class Sky extends PositionComponent with HasPaint, AutoDispose, MiniScriptFunctions {
  Sky() {
    priority = -2000;
  }

  late FragmentShader shader;

  @override
  void onLoad() async {
    final program = await FragmentProgram.fromAsset('assets/shaders/clouds.frag');
    shader = program.fragmentShader();
    paint.shader = shader;

    shader.setFloat(0, rect.width);
    shader.setFloat(1, rect.height);
  }

  @override
  render(Canvas canvas) {
    super.render(canvas);
    shader.setFloat(2, world.camera.x);
    shader.setFloat(3, world.camera.z / 5);
    canvas.drawRect(rect, paint);
  }

  final rect = const Rect.fromLTWH(0, 0, gameWidth, gameHeight / 2 - 25);
}
