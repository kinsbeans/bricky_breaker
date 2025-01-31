import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../brick_breaker.dart';
import '../config.dart';
import 'components.dart';

enum Layer {
  ball(1),
  wall(2),
  bat(4),
  brick(8),
  obstacle(16),
  deathZone(32);

  const Layer(this.value);
  final int value;
}

class DeathZone extends PositionComponent with HasGameReference<BrickBreaker> {
  DeathZone() : super(anchor: Anchor.center);
  final Paint paint = Paint()..color = Colors.red; // Define the paint variable
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize position and size in onLoad, where `game` is accessible
    position = Vector2(game.size.x / 2, game.size.y + 10); // Position below the play area
    size = Vector2(game.size.x, 20); // Width of the play area, height enough to catch the ball

    // Add a hitbox for collision detection and set its collision type
    final hitbox = RectangleHitbox();
    hitbox.collisionType = CollisionType.passive; // Set collision type here
    add(hitbox);
  }

  @override
  int get priority => 100;
}

class Ball extends CircleComponent with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
  }) : super(
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()
            ..color = brickColors[0],
          children: [CircleHitbox()],
        ) {
    initialVelocity = velocity.clone();
    _initializeParticlePool();
  }
  
  bool isFireball = false;
  Timer? _fireballTimer;
  Timer? _colorPulseTimer;
  Vector2 velocity;
  late Vector2 initialVelocity;
  double difficultyModifier;
  double maxSpeed = 400.0;
  int colorIndex = 0;
  bool lifeLost = false;
  
  final List<ParticleSystemComponent> _trailPool = [];
  double _sparkCooldown = 0.0;

  int get collisionMask => Layer.wall.value | Layer.bat.value | Layer.brick.value | Layer.obstacle.value | Layer.deathZone.value;
  void _initializeParticlePool() {
    for (int i = 0; i < 5; i++) {
      _trailPool.add(ParticleSystemComponent(particle: Particle.generate(generator: (_) => ComputedParticle(renderer: (_, __) {}))));
    }
  }

  @override
  void update(double dt) {
    if (isRemoved) return;
    
    super.update(dt);
    position += velocity * dt;
    
    _sparkCooldown -= dt;
    
    if (position.y > game.size.y && !lifeLost) {
      _handleBallLoss();
    }
  }

  void _handleBallLoss() {
    if (game.activeBalls.value > 1) {
      game.activeBalls.value--;
      removeFromParent();
    } else {
      game.loseLife();
      lifeLost = true;
      removeFromParent();
    }
  }

  void normalizeVelocity() {
  // Allow upward motion (negative Y) and restrict downward motion
  velocity.clamp(
    Vector2(-maxSpeed, -maxSpeed), // Allow full upward speed
    Vector2(maxSpeed, maxSpeed * 0.5), // Limit downward speed
  );
}


 void changeColor() {
  if (isFireball) return;
  colorIndex = (colorIndex + 1) % brickColors.length;
  paint.color = brickColors[colorIndex];
  (children.first as CircleHitbox).paint.color = brickColors[colorIndex];
}


  void addSparks(Vector2 position) {
    if (_sparkCooldown > 0) return;
    _sparkCooldown = 0.1;

    final sparkColor = brickColors[colorIndex];
    parent?.add(Spark(position: position, color: sparkColor));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    changeColor();
    
    if (intersectionPoints.isNotEmpty) {
      addSparks(intersectionPoints.first);
    }
     if (other is DeathZone) {
    _handleBallLoss();
    return;
  }
    if (other is PlayArea) {
      _handlePlayAreaCollision(intersectionPoints.first);
    } else if (other is Bat) {
      handleBatCollision(other);
    } else if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
    } else if (other is Obstacle) {
      _handleObstacleCollision(other);
    }
  }

  void _handlePlayAreaCollision(Vector2 intersectionPoint) {
    if (intersectionPoint.y <= 0) {
      velocity.y = -velocity.y;
      position.y = radius;
    } else if (intersectionPoint.x <= 0 || intersectionPoint.x >= game.size.x) {
      velocity.x = -velocity.x;
      position.x = intersectionPoint.x <= 0 ? radius : game.size.x - radius;
    }
    if (kDebugMode) print('Wall collision');
  }
 @protected
void handleBatCollision(Bat bat) {
  final batHalfWidth = bat.size.x / 2;
  final batTopY = bat.position.y - (bat.size.y / 2); // Top surface of the bat

  // Clamp the ball's X position to the bat's edges
  final clampedX = position.x.clamp(
    bat.position.x - batHalfWidth,
    bat.position.x + batHalfWidth,
  );
  
  // Closest point is on the top surface of the bat
  final closestPoint = Vector2(clampedX, batTopY);
  
  // Calculate collision normal (from bat to ball)
  final collisionNormal = (position - closestPoint).normalized();
  
  // Reflect velocity using the upward normal
  velocity.reflect(collisionNormal);
  
  // Resolve penetration to prevent overlap
  resolveCollisionPenetration(closestPoint);
  
  // Add horizontal influence based on bat position
  velocity.x += (position.x - bat.position.x) / bat.size.x * 100;
  normalizeVelocity();
}

  void _handleBrickCollision(Brick brick, Set<Vector2> intersectionPoints) {
  if (!isFireball) { // Only do normal collision handling if not fireball
    final brickHalfSize = brick.size / 2;
    final brickCenter = brick.position;
    final closestPoint = Vector2(
      position.x.clamp(brickCenter.x - brickHalfSize.x, brickCenter.x + brickHalfSize.x),
      position.y.clamp(brickCenter.y - brickHalfSize.y, brickCenter.y + brickHalfSize.y),
    );
    
    final collisionNormal = (position - closestPoint).normalized();
    velocity.reflect(collisionNormal);
    velocity.setFrom(velocity * difficultyModifier);
    resolveCollisionPenetration(closestPoint);
    normalizeVelocity();
  }

  if (!brick.hasEffect) {
    brick.add(ScaleEffect.to(
      Vector2(1.2, 1.2),
      EffectController(duration: 0.1, reverseDuration: 0.1),
    ));
    brick.hasEffect = true;
  }
  
  if (kDebugMode) print('Brick collision');
}

  void _handleObstacleCollision(Obstacle obstacle) {
    final obstacleHalfSize = obstacle.size / 2;
    final obstacleCenter = obstacle.position;
    final closestPoint = Vector2(
      position.x.clamp(obstacleCenter.x - obstacleHalfSize.x, obstacleCenter.x + obstacleHalfSize.x),
      position.y.clamp(obstacleCenter.y - obstacleHalfSize.y, obstacleCenter.y + obstacleHalfSize.y),
    );
    
    final collisionNormal = (position - closestPoint).normalized();
    velocity.reflect(collisionNormal);
    resolveCollisionPenetration(closestPoint);
    
    if (kDebugMode) print('Obstacle collision');
  }

 void resolveCollisionPenetration(Vector2 closestPoint) {
  final penetration = radius - position.distanceTo(closestPoint);
  if (penetration <= 0) return;

  // Push the ball away with a buffer to prevent sticking
  final resolutionVector = (position - closestPoint).normalized() * (penetration + 5.0);
  position += resolutionVector;
}

  void activateFireball(double duration) {
  isFireball = true;
  _colorPulseTimer?.stop();
  final originalColor = paint.color;

  // Create pulsating color effect
  add(SequenceEffect(
    [
      ColorEffect(
        const Color(0xFFFF4500), // Target color (red-orange)
        EffectController(duration: 0.1),
      ),
      ColorEffect(
        originalColor, // Return to current color
        EffectController(duration: 0.1),
      ),
    ],
    infinite: true,
  ));

  _fireballTimer = Timer(duration, onTick: () => deactivateFireball());
}

void deactivateFireball() {
  isFireball = false;
  removeWhere((component) => component is SequenceEffect);
  paint.color = brickColors[colorIndex];
  (children.first as CircleHitbox).paint.color = brickColors[colorIndex];
  _fireballTimer?.stop();
}

// Update changeColor to check fireball state

}