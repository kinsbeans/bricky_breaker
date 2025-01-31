import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../brick_breaker.dart';
import 'components.dart';

enum PowerUpType { extraLife, largerBat, slowBall, shrinkBat, fastBall, multiBall }


class PowerUp extends PositionComponent with CollisionCallbacks, HasGameReference<BrickBreaker> {
  final PowerUpType type;
  late final TextComponent text;

  PowerUp({
    required this.type,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        ) {
    // Define icons and colors for each power-up type
    IconData icon;
    Color color;
    switch (type) {
  // Existing power-up types
  case PowerUpType.extraLife:
    icon = Icons.favorite;
    color = Colors.redAccent;
    break;
  case PowerUpType.largerBat:
    icon = Icons.shield;
    color = Colors.blueAccent;
    break;
  case PowerUpType.slowBall:
    icon = Icons.slow_motion_video;
    color = Colors.greenAccent;
    break;
  case PowerUpType.shrinkBat:
    icon = Icons.minimize;
    color = Colors.purpleAccent;
    break;
  case PowerUpType.fastBall:
    icon = Icons.flash_on;
    color = Colors.yellowAccent;
    break;
  case PowerUpType.multiBall:
    icon = Icons.bubble_chart;
    color = Colors.cyanAccent;
}


    text = TextComponent(
      text: String.fromCharCode(icon.codePoint),
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: 48,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
    add(text); // Add the text component
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 150 * dt; // Increase falling speed
    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Bat) {
      applyEffect();
      removeFromParent(); // Directly remove the power-up upon collision
    }
  }

 void applyEffect() {
  switch (type) {
    // Existing effects
    case PowerUpType.extraLife:
      game.lives.value++;
      break;
    case PowerUpType.largerBat:
      game.enlargeBat(15); 
      break;
    case PowerUpType.slowBall:
      game.slowDownBall(15); 
      break;
    case PowerUpType.shrinkBat:
      game.shrinkBat(15); 
      break;
    case PowerUpType.fastBall:
      game.fastBall(15); 
      break;
    case PowerUpType.multiBall:
      game.activateMultiBall(); 
      break;
  }
}


}
