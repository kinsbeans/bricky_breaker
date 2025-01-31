import 'package:brick_breaker/src/config.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../brick_breaker.dart';
import 'components.dart';
import 'dart:math' as math;

class Obstacle extends PositionComponent with CollisionCallbacks, HasGameReference<BrickBreaker> {
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


class TeleportingObstacle extends Obstacle {
  late Timer _teleportTimer;

  TeleportingObstacle({
    required super.position,
    required super.size,
    super.color,
  }) {
    _teleportTimer = Timer(10, repeat: true, onTick: () {
      // Pop-out animation
      add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.5),
          onComplete: () {
            teleport();

            // Pop-in animation
            add(
              ScaleEffect.to(
                Vector2(1.0, 1.0),
                EffectController(duration: 0.5),
              ),
            );
          },
        ),
      );
    });
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _teleportTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _teleportTimer.update(dt);
  }
 @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Ball) {
      // Change to a random color when hit
      color = Colors.primaries[DateTime.now().millisecondsSinceEpoch % brickColors.length];
    }
  }
  void teleport() {
    // Randomly choose new coordinates for the obstacle
    final centerX = game.size.x / 2;
    final centerY = game.size.y / 2;
    final halfWidth = game.size.x * 0.15; // 50% / 2
    final halfHeight = game.size.y * 0.15; // 50% / 2

    final newX = (math.Random().nextDouble() * 2 - 1) * halfWidth + centerX;
    final newY = (math.Random().nextDouble() * 2 - 1) * halfHeight + centerY;
    
    position = Vector2(newX, newY);
  }
}