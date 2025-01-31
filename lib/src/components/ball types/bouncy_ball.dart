import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components.dart';

class BouncyBall extends Ball {
  BouncyBall({
    required super.velocity,
    required Vector2 super.position,
    required super.radius,
    required super.difficultyModifier,
  }) {
    paint.color = Colors.green;
    maxSpeed = 800.0; 
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayArea || other is Bat || other is Brick || other is Obstacle) {
      // Exponentially increase speed on each collision
      velocity.setFrom(velocity * (difficultyModifier * difficultyModifier));
      normalizeVelocity();
    }
  }

  @override
  void normalizeVelocity() {
    if (velocity.length > maxSpeed) {
      velocity.setFrom(velocity.normalized() * maxSpeed);
    } else if (velocity.length < maxSpeed * 0.5) {
      velocity.setFrom(velocity.normalized() * maxSpeed * 0.5);
    }
  }
}
