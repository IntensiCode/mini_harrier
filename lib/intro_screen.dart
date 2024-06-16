import 'package:mini_harrier/core/mini_soundboard.dart';

import 'core/mini_common.dart';
import 'input/mini_shortcuts.dart';
import 'scripting/mini_script.dart';
import 'scripting/subtitles_component.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

class IntroScreen extends MiniScriptComponent with HasAutoDisposeShortcuts {
  IntroScreen([this.nextScreen = Screen.stage1]);

  final Screen nextScreen;

  @override
  void onMount() {
    super.onMount();
    onKey('<Space>', () => _leave());
  }

  void _leave() {
    clearScript();
    at(0.0, () => fadeOutAll());
    at(1.0, () => showScreen(nextScreen));
    executeScript();
  }

  @override
  void onLoad() async {
    super.onLoad();

    fontSelect(menuFont, scale: fontScale);

    at(0.0, () async => fadeIn(await spriteXY('intro-woman-oh-no.png', xCenter, yCenter)));
    at(1.0, () => subtitles(_woman_1, 4, audio: 'woman-somebody.mp3'));
    at(5.0, () => fadeOutAll());
    at(0.0, () async => fadeIn(await spriteXY('intro-captain.png', xCenter, yCenter)));
    at(1.0, () => subtitles(_captain, 3, audio: 'captain-whodunnit.mp3'));
    at(4.0, () => fadeOutAll());
    at(0.0, () async => fadeIn(await spriteXY('intro-woman-they-did.png', xCenter, yCenter)));
    at(1.0, () => subtitles(_woman_2, 3, audio: 'woman-it-was-them.mp3'));
    at(4.0, () => fadeOutAll());
    at(0.0, () async => fadeIn(await spriteXY('intro-aliens.png', xCenter, yCenter)));
    at(1.0, () => subtitles(_aliens, 3, audio: 'aliens-intro.ogg'));
    at(4.0, () => fadeOutAll());
    at(0.0, () => showScreen(nextScreen));
  }

  final _woman_1 = 'Oh no! Something terrible happened! Somebody did it!';
  final _captain = 'Whodunnit?';
  final _woman_2 = 'It was them!';
  final _aliens = 'AKLHJ)DY&G#_%IJKNDSFG()O*H!';

  void subtitles(String text, double? autoClearSeconds, {String? image, String? audio}) {
    add(SubtitlesComponent(text, autoClearSeconds, image));
    if (audio != null) soundboard.playAudio(audio);
  }
}
