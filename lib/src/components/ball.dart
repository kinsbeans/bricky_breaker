import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../brick_breaker.dart';
import '../config.dart';
import 'components.dart';

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
  }

  Vector2 velocity;
  late Vector2 initialVelocity;
  double difficultyModifier;
  double maxSpeed = 300.0;
  int colorIndex = 0;
  bool lifeLost = false;

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    normalizeVelocity();
    addTrail();
    if (position.y > game.size.y && !lifeLost) {
      if (game.activeBalls.value > 1) {
        game.activeBalls.value--;
        removeFromParent();
      } else {
        game.loseLife();
        lifeLost = true;
        removeFromParent();
      }
    }
  }

  void normalizeVelocity() {
    velocity.clamp(
      Vector2.zero()..setAll(maxSpeed * 0.5),
      Vector2.all(maxSpeed),
    );
  }

  void changeColor() {
    colorIndex = (colorIndex + 1) % brickColors.length;
    paint.color = brickColors[colorIndex];
    children.whereType<CircleHitbox>().forEach((hitbox) {
      hitbox.paint.color = brickColors[colorIndex];
    });
  }

  void addTrail() {
    final trailParticle = Particle.generate(
      count: 5,
      generator: (i) {
        return MovingParticle(
          from: position.clone(),
          to: position.clone() - velocity.normalized() * 20,
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final initialRadius = this.radius * 0.6;
              final radius = initialRadius * (1 - particle.progress);
              final particlePaint = Paint()..color = paint.color.withOpacity(1 - particle.progress);
              canvas.drawCircle(Offset.zero, radius, particlePaint);
            },
            lifespan: 0.2,
          ),
        );
      },
    );

    parent?.add(ParticleSystemComponent(particle: trailParticle));
  }

  void addSparks(Vector2 position) {
    final sparkColor = brickColors[colorIndex];
    parent?.add(Spark(position: position, color: sparkColor));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    changeColor();
    addSparks(intersectionPoints.first);

    if (other is PlayArea) {
      handlePlayAreaCollision(intersectionPoints.first);
    } else if (other is Bat) {
      handleBatCollision(other);
    } else if (other is Brick) {
      handleBrickCollision(other, intersectionPoints);
    } else if (other is Obstacle) {
      handleObstacleCollision(other);
    }
  }

void handlePlayAreaCollision(Vector2 intersectionPoint) {
  if (intersectionPoint.y <= 0) {
    // Collision with top wall
    velocity.y = -velocity.y;
    position.y = radius; // Move the ball back inside the play area
    print('Top wall collision');
  } else if (intersectionPoint.x <= 0 || intersectionPoint.x >= game.size.x) {
    // Collision with side walls
    velocity.x = -velocity.x;
    position.x = intersectionPoint.x <= 0 
        ? radius 
        : game.size.x - radius; // Move the ball back inside the play area
    print('Side wall collision');
  }
}

void handleBatCollision(Bat bat) {
  final closestPoint = Vector2(
    position.x.clamp(bat.position.x - bat.size.x / 2, bat.position.x + bat.size.x / 2),
    position.y.clamp(bat.position.y - bat.size.y / 2, bat.position.y + bat.size.y / 2),
  );
  final collisionNormal = (position - closestPoint).normalized();
  velocity.reflect(collisionNormal);
  resolveCollisionPenetration(closestPoint);
  velocity.x += (position.x - bat.position.x) / bat.size.x * 100; // Add directional influence
  normalizeVelocity();
  print('Bat collision');
}

void handleBrickCollision(Brick brick, Set<Vector2> intersectionPoints) {
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
  brick.add(ScaleEffect.to(
    Vector2(1.2, 1.2),
    EffectController(duration: 0.1, reverseDuration: 0.1),
  ));
  changeColor(); // Change color on collision
  addSparks(intersectionPoints.first); // Add sparks on collision
  print('Brick collision');
}

void handleObstacleCollision(Obstacle obstacle) {
  final obstacleHalfSize = obstacle.size / 2;
  final obstacleCenter = obstacle.position;
  final closestPoint = Vector2(
    position.x.clamp(obstacleCenter.x - obstacleHalfSize.x, obstacleCenter.x + obstacleHalfSize.x),
    position.y.clamp(obstacleCenter.y - obstacleHalfSize.y, obstacleCenter.y + obstacleHalfSize.y),
  );
  final collisionNormal = (position - closestPoint).normalized();
  velocity.reflect(collisionNormal);
  resolveCollisionPenetration(closestPoint);
  normalizeVelocity();
  print('Obstacle collision');
}

void resolveCollisionPenetration(Vector2 closestPoint) {
  final distance = position.distanceTo(closestPoint);
  final penetration = radius - distance;
  if (penetration > 0) {
    final resolutionVector = (position - closestPoint).normalized() * penetration;
    position += resolutionVector;
    print('Resolved penetration: $resolutionVector');
  }
}
}