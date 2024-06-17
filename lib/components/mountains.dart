import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../core/mini_3d.dart';
import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';

class Mountains extends PositionComponent with HasPaint, AutoDispose, MiniScriptFunctions {
  Mountains() {
    priority = -1000;
    position.y = gameHeight / 4 + 2;
  }

  late FragmentShader shader;

  @override
  void onLoad() async {
    final program = await FragmentProgram.fromAsset('assets/shaders/mountains.frag');
    shader = program.fragmentShader();
    paint.shader = shader;

    shader.setFloat(0, rect.width);
    shader.setFloat(1, rect.height);
  }

  @override
  render(Canvas canvas) {
    super.render(canvas);
    shader.setFloat(2, world.camera.x / 3000);

    if (kIsWeb) {
      final paint = Paint();
      paint.shader = shader;
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  final rect = const Rect.fromLTWH(0, 0, gameWidth, gameHeight / 4);
}
