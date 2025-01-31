import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart'; // Ensure this imports the brickColors array

class Bat extends PositionComponent with DragCallbacks, CollisionCallbacks, HasGameReference<BrickBreaker> {
  Bat({
    required this.cornerRadius,
    required super.position,
    required super.size,
  }) : super(
          anchor: Anchor.center,
          children: [RectangleHitbox()],
        );

  final Radius cornerRadius;
  final Paint _paint = Paint()
    ..color = brickColors[0] // Initial color from brickColors
    ..style = PaintingStyle.fill;

  int colorIndex = 0; // Initialize color index

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        cornerRadius,
      ),
      _paint,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final newPositionX = (position.x + event.localDelta.x).clamp(
      size.x / 2,
      game.size.x - size.x / 2,
    );
    position.x = newPositionX;
  }

  void moveBy(double dx) {
    add(MoveEffect.by(
      Vector2(dx, 0),
      EffectController(duration: 0.1),
    ));
  }

  void enlarge(double factor) {
  final newWidth = size.x * factor;
  size.x = newWidth.clamp(size.x, game.size.x); // Cap the width to screen width
}
void resize(double factor) {
  final newWidth = size.x * factor;
  size.x = newWidth.clamp(size.x * 0.5, game.size.x); // Adjust width between half the original size and the screen width
}


  void changeColor() {
    colorIndex = (colorIndex + 1) % brickColors.length; // Cycle through brickColors
    _paint.color = brickColors[colorIndex]; // Change color immediately
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      changeColor(); // Change to a new color when hit
    }
  }
}
