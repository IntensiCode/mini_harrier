import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../core/common.dart';
import '../core/mini_3d.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';

class Sky extends PositionComponent with HasPaint, AutoDispose, GameScriptFunctions {
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
    shader.setFloat(3, world.camera.z / 50);

    if (kIsWeb) {
      final paint = Paint();
      paint.shader = shader;
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  final rect = const Rect.fromLTWH(0, 0, gameWidth, gameHeight / 2 - 10);
}
