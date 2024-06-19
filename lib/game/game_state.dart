import 'package:signals_core/signals_core.dart';

GameState state = GameState();

enum GameStateId {
  charge,
  lives,
  missiles,
  score,
  shields,
}

class GameState {
  final data = {
    GameStateId.charge: signal(0),
    GameStateId.lives: signal(3),
    GameStateId.missiles: signal(0),
    GameStateId.score: signal(0),
    GameStateId.shields: signal(3),
  };

  operator [](GameStateId id) => data[id]!.value;

  operator []=(GameStateId id, int value) => data[id]!.value = value;

  int get charge => data[GameStateId.charge]!.value;

  int get lives => data[GameStateId.lives]!.value;

  int get missiles => data[GameStateId.missiles]!.value;

  int get score => data[GameStateId.score]!.value;

  int get shields => data[GameStateId.shields]!.value;

  set charge(int value) => data[GameStateId.charge]!.value = value;

  set lives(int value) => data[GameStateId.lives]!.value = value;

  set missiles(int value) => data[GameStateId.missiles]!.value = value;

  set score(int value) => data[GameStateId.score]!.value = value;

  set shields(int value) => data[GameStateId.shields]!.value = value;
}
