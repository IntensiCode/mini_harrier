import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class BlinkEffect extends Effect {
  BlinkEffect({this.duration = 1, this.interval = 0.2}) : super(LinearEffectController(duration));

  final double duration;
  final double interval;

  @override
  void apply(double progress) {
    final visible = progress * duration ~/ interval;
    (parent as HasVisibility).isVisible = visible.isEven;
  }
}
