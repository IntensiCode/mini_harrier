import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import 'mini_3d.dart';

sealed class Message {}

class ChallengeComplete extends Message {}

class EnemiesDefeated extends Message {}

class GetClosestEnemyPosition extends Message {
  GetClosestEnemyPosition(this.position, this.onResult);

  final Vector2 position;
  final void Function(Vector2) onResult;
}

class NextLevel extends Message {}

class PlayerDestroyed extends Message {}

class ShowScreen extends Message {
  ShowScreen(this.screen);

  final Screen screen;
}

class SpawnBall extends Message {
  SpawnBall(this.position);

  final Vector2 position;
}

class SpawnEffect extends Message {
  SpawnEffect({required this.kind, required this.anchor, this.delaySeconds, this.atHalfTime, this.velocity});

  final EffectKind kind;
  final Component3D anchor;
  final double? delaySeconds;
  final Function()? atHalfTime;
  final Vector3? velocity;
}

class SpawnExtra extends Message {
  SpawnExtra(this.position, [this.kind]);

  final Vector3 position;
  final Set<ExtraKind>? kind;
}
// there are better solutions available than this. but this works for the
// simple game demo at hand.

extension ComponentExtension on Component {
  Messaging get messaging {
    Component? probed = this;
    while (probed is! Messaging) {
      probed = probed?.parent;
      if (probed == null) throw StateError('no messaging mixin found');
    }
    return probed;
  }
}

mixin Messaging on Component {
  final listeners = <Type, List<dynamic>>{};

  Disposable listen<T extends Message>(void Function(T) callback) {
    listeners[T] ??= [];
    listeners[T]!.add(callback);
    return Disposable.wrap(() {
      listeners[T]?.remove(callback);
    });
  }

  void send<T extends Message>(T message) {
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