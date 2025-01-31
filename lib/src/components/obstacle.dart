import 'package:brick_breaker/src/config.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'components.dart';

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.grey,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  Color color;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Define the visual representation of the obstacle
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), paint);
  }
}

class ColoredObstacle extends Obstacle {
  ColoredObstacle({
    required super.position,
    required super.size,
    required Color initialColor,
  }) : super(
          color: initialColor,
        );

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Ball) {
      // Change to a random color when hit
      color = Colors.primaries[DateTime.now().millisecondsSinceEpoch % brickColors.length];
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), paint);
  }
}
