import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_core/signals_core.dart';

final debug = signal(kDebugMode);
bool dev = kDebugMode;

const double gameWidth = 320;
const double gameHeight = 256;
final Vector2 gameSize = Vector2(gameWidth, gameHeight);

const minHeight = 0.0;
const maxHeight = 250.0;
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

// for this simple game demo, all sprites will be in here after game's onLoad.
late SpriteSheet sprites;

SpriteAnimation player() => sprites.createAnimation(row: 0, stepTime: 0.1, from: 3, to: 6);

SpriteAnimation exhaust() => sprites.createAnimation(row: 1, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation bonny() => sprites.createAnimation(row: 2, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation looker() => sprites.createAnimation(row: 3, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation smiley() => sprites.createAnimation(row: 4, stepTime: 0.1, from: 1, to: 9);

SpriteAnimation explosion() => sprites.createAnimation(row: 6, stepTime: 0.1, from: 3, to: 8)..loop = false;

SpriteAnimation sparkle() => sprites.createAnimation(row: 7, stepTime: 0.1, from: 3, to: 7)..loop = false;

SpriteAnimation hit() => sprites.createAnimation(row: 9, stepTime: 0.05, from: 3, to: 9)..loop = false;

SpriteAnimation laser() => sprites.createAnimation(row: 8, stepTime: 1.0, from: 3, to: 6);

SpriteAnimation missile() => sprites.createAnimation(row: 10, stepTime: 0.1, from: 3, to: 7);

SpriteAnimation energyBall() => sprites.createAnimation(row: 11, stepTime: 0.1, from: 3, to: 7);

SpriteAnimation appear() => sprites.createAnimation(row: 12, stepTime: 0.1, from: 0, to: 9)..loop = false;

SpriteAnimation shield() => sprites.createAnimation(row: 13, stepTime: 0.05, from: 0, to: 10);

SpriteAnimation smoke() => sprites.createAnimation(row: 14, stepTime: 0.05, from: 0, to: 11)..loop = false;

Future<SpriteAnimation> explosion32() => game.loadSpriteAnimation(
    'explosion96.png',
    SpriteAnimationData.sequenced(
      amount: 12,
      stepTime: 0.1,
      textureSize: Vector2(96, 96),
      loop: false,
    ));

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

enum MiniEffectKind {
  appear,
  explosion,
  hit,
  smoke,
  sparkle,
}

enum MiniItemKind {
  laserCharge(0, 1),
  shield(1, 1),
  missile(2, 1),
  score1(3, 1),
  score2(4, 0.8),
  score3(5, 0.5),
  extraLife(6, 0.01),
  ;

  final int column;
  final double probability;

  const MiniItemKind(this.column, this.probability);
}

mixin Collector {
  void collect(MiniItemKind kind);
}

mixin Defender {
  bool onHit([int hits = 1]);
}
