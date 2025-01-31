import 'package:flutter/material.dart';
import '../components.dart';
class HeavyBall extends Ball {
  HeavyBall({
    required super.velocity,
    required super.position,
    required super.radius,
    required super.difficultyModifier,
  }) : super() {
    paint.color = Colors.blue;
    difficultyModifier = 0.95;
  }

  @override
  void handleBatCollision(Bat bat) {
    super.handleBatCollision(bat); // Call base collision logic
    velocity.setFrom(velocity * difficultyModifier); // Apply modifier AFTER collision
    normalizeVelocity();
  }
}