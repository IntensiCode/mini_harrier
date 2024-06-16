import 'dart:ui';

import 'package:flame/components.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';

class Checkerboard extends PositionComponent with HasPaint, AutoDispose, MiniScriptFunctions {
  Checkerboard() {
    priority = -1000;
  }

  late FragmentShader shader;

  @override
  void onLoad() async {
    final program = await FragmentProgram.fromAsset('assets/shaders/checkerboard.frag');
    shader = program.fragmentShader();
    paint.shader = shader;

    shader.setVec4(0, const Color(0xFF806030));
    shader.setVec4(4, const Color(0xFFc0a050));
    shader.setFloat(8, rect.width);
    shader.setFloat(9, rect.height);
    shader.setFloat(10, 32);
    shader.setFloat(11, world.d);
  }

  @override
  render(Canvas canvas) {
    super.render(canvas);
    shader.setFloat(12, world.camera.x);
    shader.setFloat(13, world.camera.y);
    shader.setFloat(14, world.camera.z);
    canvas.drawRect(rect, paint);
  }

  final rect = const Rect.fromLTWH(0, gameHeight / 2, gameWidth, gameHeight / 2);
}
