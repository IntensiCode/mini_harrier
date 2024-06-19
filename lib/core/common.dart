import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_core/signals_core.dart';

final debug = signal(kDebugMode);
bool dev = kDebugMode;

const double gameWidth = 320;
const double gameHeight = 256;
final Vector2 gameSize = Vector2(gameWidth, gameHeight);

const baseSpeed = -500.0;
const minHeight = 0.0;
const maxHeight = 500.0;
const midHeight = minHeight + (maxHeight - minHeight) / 2;
const maxLeft = -200.0;
const maxRight = 200.0;

const fontScale = gameHeight / 500;
const xCenter = gameWidth / 2;
const yCenter = gameHeight / 2;
const lineHeight = 24 * fontScale;
const debugHeight = 12 * fontScale;

late Game game;
late Images images;
late CollisionDetection collisions;

// to avoid importing materials elsewhere (which causes clashes sometimes), some color values right here:
const transparent = Colors.transparent;
const black = Colors.black;
const white = Colors.white;

Future<SpriteAnimation> energyBalls16() => game.loadSpriteAnimation(
      'energy_balls_alt.png',
      SpriteAnimationData.sequenced(
        amount: 16,
        amountPerRow: 8,
        stepTime: 0.03,
        textureSize: Vector2(16, 16),
      ),
    );

Paint pixelPaint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

enum Screen {
  game,
  intro,
  stage1,
  title,
}

enum EffectKind {
  explosion,
  smoke,
  sparkle,
}

enum ExtraKind {
  energy(1),
  firePower(1),
  missile(0.2),
  ;

  final double probability;

  const ExtraKind(this.probability);
}

mixin Collector {
  void collect(ExtraKind kind);
}

mixin Defender {
  bool onHit([int hits = 1]);
}
