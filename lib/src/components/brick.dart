import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'bat.dart';
import 'power_up.dart' as pu;

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  final int hitPoints;
  int currentHitPoints;
  late RectangleComponent healthBar;

  Brick({required super.position, required Color color, required this.hitPoints})
      : currentHitPoints = hitPoints,
        super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = color.withOpacity(1.0), // Set initial opacity to 1.0
          children: [RectangleHitbox()],
        ) {
    // Initialize the health bar
    healthBar = RectangleComponent(
      position: Vector2(0, -brickHeight / 2 - 5), // Position above the brick
      size: Vector2(brickWidth, 5),
      paint: Paint()..color = Colors.green,
    );
    add(healthBar);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    currentHitPoints--;

    // Update health bar size/color based on current hit points
    updateHealthBar();

    if (currentHitPoints <= 0) {
      removeFromParent();
      game.score.value++;

      // 10% chance to spawn a power-up
      if (math.Random().nextDouble() < 1) {
        spawnPowerUp();
      }

      if (game.world.children.query<Brick>().length == 1) {
        game.playState = PlayState.won;
        game.world.removeAll(game.world.children.query<Ball>());
        game.world.removeAll(game.world.children.query<Bat>());
      }
    }

    // Update brick opacity based on current hit points
    updateOpacity();
  }

  void updateHealthBar() {
    final healthPercentage = currentHitPoints / hitPoints;
    healthBar.size.x = brickWidth * healthPercentage;

    // Change the color of the health bar based on remaining health
    if (healthPercentage > 0.5) {
      healthBar.paint.color = Colors.green;
    } else if (healthPercentage > 0.25) {
      healthBar.paint.color = Colors.yellow;
    } else {
      healthBar.paint.color = Colors.red;
    }
  }

  void updateOpacity() {
    final healthPercentage = currentHitPoints / hitPoints;
    paint.color = paint.color.withOpacity(healthPercentage.clamp(0.2, 1.0));
  }

  void spawnPowerUp() {
    final powerUpType = pu.PowerUpType.values[math.Random().nextInt(pu.PowerUpType.values.length)];
    game.world.add(pu.PowerUp(
      type: powerUpType,
      position: position,
      size: Vector2(50, 50),
    ));
  }
}
