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
  bool hasEffect  = false;
  late Rect _healthBar;

  Brick({required super.position, required Color color, required this.hitPoints})
      : currentHitPoints = hitPoints,
        super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = color.withOpacity(1.0),
          children: [RectangleHitbox()],
        ) {
    // Initialize the health bar positioned at the bottom inside the brick
    _healthBar = Rect.fromLTWH(0, size.y - 5, size.x, 5);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw the brick
    final brickRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      brickRect,
      Paint()..color = paint.color,
    );
    
    // Draw the health bar background (red)
    canvas.drawRect(
      _healthBar,
      Paint()..color = Colors.red,
    );

    // Draw the current health bar (green)
    canvas.drawRect(
      Rect.fromLTWH(_healthBar.left, _healthBar.top, _healthBar.width * (currentHitPoints / hitPoints), _healthBar.height),
      Paint()..color = Colors.green,
    );
  }

 @override
void onCollisionStart(
    Set<Vector2> intersectionPoints, PositionComponent other) {
  super.onCollisionStart(intersectionPoints, other);
  
  if (other is Ball) {
    final ball = other;
    currentHitPoints -= ball.isFireball ? hitPoints : 1;
  }

  if (currentHitPoints <= 0) {
    removeFromParent();
    game.score.value++;

    if (math.Random().nextDouble() < 0.40) {
      spawnPowerUp();
    }

    if (game.world.children.query<Brick>().length == 1) {
      game.playState = PlayState.won;
      game.world.removeAll(game.world.children.query<Ball>());
      game.world.removeAll(game.world.children.query<Bat>());
    }
  }
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
