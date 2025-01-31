import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components.dart';

class HeavyBall extends Ball {
  HeavyBall({
    required super.velocity,
    required Vector2 super.position,
    required super.radius,
    required super.difficultyModifier,
  }) {
    paint.color = Colors.blue;
    difficultyModifier = 0.9; // Slightly reduce momentum on each collision
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayArea || other is Bat || other is Brick || other is Obstacle) {
      // Apply difficulty modifier to reduce speed slightly
      velocity.setFrom(velocity * difficultyModifier);

      // Ensure the ball doesn't lose too much momentum
      if (velocity.length < 100) {
        velocity.setFrom(velocity.normalized() * 100); // Set a minimum speed
      }

      normalizeVelocity();

      // Debug logging
      print('HeavyBall collision with ${other.runtimeType}');
      print('Velocity after collision: $velocity');
    }
  }
}