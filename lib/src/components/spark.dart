import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class Spark extends Component {
  Spark({
    required Vector2 position,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    add(ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 15, // Increase the number of particles
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2.random() * 300 - Vector2(150, 150),
          speed: Vector2.random() * 150 - Vector2(75, 75),
          child: CircleParticle(
            radius: 3.0, // Increase the size of the particles
            paint: paint,
          ),
        ),
      ),
    ));
  }
}
