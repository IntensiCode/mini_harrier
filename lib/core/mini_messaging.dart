import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../util/auto_dispose.dart';
import 'mini_3d.dart';

sealed class MiniMessage {}

class ChallengeComplete extends MiniMessage {}

class EnemiesDefeated extends MiniMessage {}

class GetClosestEnemyPosition extends MiniMessage {
  GetClosestEnemyPosition(this.position, this.onResult);

  final Vector2 position;
  final void Function(Vector2) onResult;
}

class NextLevel extends MiniMessage {}

class PlayerDestroyed extends MiniMessage {}

class ShowScreen extends MiniMessage {
  ShowScreen(this.screen);

  final Screen screen;
}

class SpawnBall extends MiniMessage {
  SpawnBall(this.position);

  final Vector2 position;
}

class SpawnEffect extends MiniMessage {
  SpawnEffect({required this.kind, required this.anchor, this.delaySeconds, this.atHalfTime, this.velocity});

  final MiniEffectKind kind;
  final Component3D anchor;
  final double? delaySeconds;
  final Function()? atHalfTime;
  final Vector3? velocity;
}

class SpawnItem extends MiniMessage {
  SpawnItem(this.position, [this.kind]);

  final Vector2 position;
  final Set<MiniItemKind>? kind;
}
// there are better solutions available than this. but this works for the
// simple game demo at hand.

extension ComponentExtension on Component {
  MiniMessaging get messaging {
    Component? probed = this;
    while (probed is! MiniMessaging) {
      probed = probed?.parent;
      if (probed == null) throw StateError('no messaging mixin found');
    }
    return probed;
  }
}

mixin MiniMessaging on Component {
  final listeners = <Type, List<dynamic>>{};

  Disposable listen<T extends MiniMessage>(void Function(T) callback) {
    listeners[T] ??= [];
    listeners[T]!.add(callback);
    return Disposable.wrap(() {
      listeners[T]?.remove(callback);
    });
  }

  void send<T extends MiniMessage>(T message) {
    final listener = listeners[T];
    if (listener == null || listener.isEmpty) {
      logWarn('no listener for $T in $listeners');
    } else {
      listener.forEach((it) => it(message));
    }
  }

  @override
  void onRemove() => listeners.clear();
}
