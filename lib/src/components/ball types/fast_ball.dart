import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components.dart';

class FastBall extends Ball {
  FastBall({
    required super.velocity,
    required Vector2 super.position,
    required super.radius,
    required super.difficultyModifier,
  }) {
    paint.color = Colors.red;
    maxSpeed = 500.0;// Ensure the hitbox is added
  }
  
  @override
  void normalizeVelocity() {
    velocity.clamp(
      Vector2.all(-maxSpeed),
      Vector2.all(maxSpeed),
    );
  }
}
