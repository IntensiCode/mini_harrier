import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'core/common.dart';
import 'core/messaging.dart';
import 'game/stage1/stage_1.dart';
import 'intro_screen.dart';
import 'title_screen.dart';

class GameWorld extends World {
  int level = 1;

  @override
  void onLoad() {
    messaging.listen<NextLevel>((_) => nextLevel());
    messaging.listen<ShowScreen>((it) => _showScreen(it.screen));
  }

  void _showScreen(Screen it) {
    logInfo(it);
    switch (it) {
      case Screen.game:
        showGame();
        break;

      case Screen.intro:
        showIntro();
        break;

      case Screen.stage1:
        showStage1();
        break;

      case Screen.title:
        level = 1;
        showTitle();
        break;
    }
  }

  void showGame() {
    removeAll(children);
  }

  void showIntro() {
    removeAll(children);
    add(IntroScreen());
  }

  void showStage1() {
    removeAll(children);
    add(Stage1());
  }

  void showTitle() {
    removeAll(children);
    add(TitleScreen());
  }

  void previousLevel() {
    if (level > 1) level--;
    showGame();
  }

  void nextLevel() {
    level++;
    logInfo('next level $level');
    showGame();
  }
}
