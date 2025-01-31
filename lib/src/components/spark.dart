import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class Spark extends Component {
  Spark({
    required Vector2 position,
    required Color color,
  }) {
    final paint = Paint()..color = color;

    // Use a simpler particle system with fewer particles
    add(ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 10, // Reduced particle count
        generator: (i) => MovingParticle(
          from: Vector2.zero(),
          to: Vector2.random() * 100 - Vector2(50, 50), // Simpler movement
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final radius = 3.0 * (1 - particle.progress); // Fade out effect
              canvas.drawCircle(Offset.zero, radius, paint);
            },
            lifespan: 0.3, // Shorter lifespan
          ),
        ),
      ),
    ));
  }
}