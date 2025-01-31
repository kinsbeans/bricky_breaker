import 'dart:async';
import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';
import 'config.dart';

enum PlayState { welcome, playing, gameOver, won }

class PowerUpEffect {
  String name;
  IconData icon;
  double duration;
  double initialDuration;
  double yPosition;
  double opacity;
  Timer? timer;

  PowerUpEffect(this.name, this.icon, this.duration, this.yPosition, this.opacity)
      : initialDuration = duration;
}

class BrickBreaker extends FlameGame with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: gameWidth,
            height: gameHeight,
          ),
        );

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> lives = ValueNotifier(3);
  final ValueNotifier<int> activeBalls = ValueNotifier<int>(1);
  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;

  late PlayState _playState;
  late String selectedBallType;

  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    _updateOverlays();
  }

  void _updateOverlays() {
    overlays.clear();
    if (playState == PlayState.welcome || playState == PlayState.gameOver || playState == PlayState.won) {
      overlays.add(playState.name);
    } else if (playState == PlayState.playing) {
      overlays.remove(PlayState.welcome.name);
      overlays.remove(PlayState.gameOver.name);
      overlays.remove(PlayState.won.name);
      overlays.remove('BallSelection');
    }
  }

  @override
  void onRemove() {
    activeBalls.dispose();
    super.onRemove();
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    playState = PlayState.welcome;
  }

  void startGame() {
    if (selectedBallType.isEmpty) return;

    playState = PlayState.playing;
    score.value = 0;
    lives.value = 3;
    world.removeAll(world.children.query<PowerUp>());
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());
    world.removeAll(world.children.query<Obstacle>());
    clearPowerUps();

    final initialVelocity = Vector2(
      (rand.nextDouble() - 0.5) * width * 0.8,
      height * 0.3,
    ).normalized()..scale(height / 4);

    switch (selectedBallType) {
      case 'fast':
        world.add(FastBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      case 'heavy':
        world.add(HeavyBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      case 'bouncy':
        world.add(BouncyBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      default:
        world.add(Ball(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
    }
 add(DeathZone());
    world.add(Bat(
        size: Vector2(batWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95)));

    final obstacleSize = Vector2(150, 50);
    final obstacles = [
      ColoredObstacle(
        position: Vector2(width * (0.5 - 0.25), height * 0.75),
        size: obstacleSize,
        initialColor: Colors.pink,
      ),
      ColoredObstacle(
        position: Vector2(width * (0.5 + 0.25), height * 0.75),
        size: obstacleSize,
        initialColor: Colors.green,
      ),
    ];
    world.addAll(obstacles);

    final teleportingObstacles = [
      TeleportingObstacle(
        position: Vector2(width * 0.25, height * 0.5),
        size: obstacleSize,
        color: Colors.orange,
      ),
      TeleportingObstacle(
        position: Vector2(width * 0.75, height * 0.5),
        size: obstacleSize,
        color: Colors.purple,
      ),
    ];
    world.addAll(teleportingObstacles);

    world.addAll([
  for (var i = 0; i < brickColors.length; i++)
    for (var j = 1; j <= 5; j++)
      Brick(
        position: Vector2(
          (i + 0.5) * brickWidth + (i + 1) * brickGutter,
          (j + 2.0) * brickHeight + j * brickGutter,
        ),
        color: brickColors[i],
        hitPoints: (math.Random().nextDouble() < 0.20) ? 5 : 1, // 20% chance for high hit points
      ),
]);


  }

  final List<PowerUpEffect> activePowerUps = [];

void shrinkBat(double duration) {
  final bat = world.children.whereType<Bat>().firstOrNull;
  if (bat != null) {
    bat.resize(0.5); // Shrink the bat
  }
  activatePowerUp('Shrink Bat', Icons.minimize, duration);
}


void fastBall(double duration) {
  final ball = world.children.whereType<Ball>().firstOrNull;
  if (ball != null) {
    ball.velocity *= 2.0; // Increase ball speed
  }
  activatePowerUp('Fast Ball', Icons.flash_on, duration);
}


void activateMultiBall() {
  final existingBall = world.children.whereType<Ball>().firstOrNull;
  if (existingBall != null) {
    final originalSpeed = existingBall.velocity.length; // Get the speed of the original ball

    for (int i = 0; i < 2; i++) { // Create 2 additional balls
      final newVelocity = existingBall.velocity.clone()
        ..rotate((i + 1) * 0.3)
        ..normalize()
        ..scale(originalSpeed); // Scale to original speed

      // Use existing ball type logic to create the new ball
      switch (existingBall.runtimeType) {
        case FastBall:
          world.add(FastBall(
            difficultyModifier: existingBall.difficultyModifier,
            radius: existingBall.radius,
            position: existingBall.position.clone(),
            velocity: newVelocity,
          ));
          break;
        case HeavyBall:
          world.add(HeavyBall(
            difficultyModifier: existingBall.difficultyModifier,
            radius: existingBall.radius,
            position: existingBall.position.clone(),
            velocity: newVelocity,
          ));
          break;
        case BouncyBall:
          world.add(BouncyBall(
            difficultyModifier: existingBall.difficultyModifier,
            radius: existingBall.radius,
            position: existingBall.position.clone(),
            velocity: newVelocity,
          ));
          break;
        default:
          world.add(Ball(
            difficultyModifier: existingBall.difficultyModifier,
            radius: existingBall.radius,
            position: existingBall.position.clone(),
            velocity: newVelocity,
          ));
      }

      activeBalls.value++; // Increase the active balls counter
    }
  }
}

void activateFireball(double duration) {
  for (final ball in world.children.whereType<Ball>()) {
    ball.activateFireball(duration);
  }
  activatePowerUp('Fireball', Icons.local_fire_department, duration);
}

  void clearPowerUps() {
  for (final effect in activePowerUps) {
    effect.timer?.cancel(); // Cancel the timer
    deactivatePowerUp(effect); // Revert the effect
  }
  activePowerUps.clear(); // Clear the list
}
  void enlargeBat(double duration) {
    final bat = world.children.whereType<Bat>().firstOrNull;
    if (bat != null) {
      bat.enlarge(1.5);
    }
    activatePowerUp('Larger Bat', Icons.shield, duration);
  }

  void slowDownBall(double duration) {
    final ball = world.children.whereType<Ball>().firstOrNull;
    if (ball != null) {
      ball.velocity *= 0.5;
    }
    activatePowerUp('Slow Ball', Icons.slow_motion_video, duration);
  }

  void increaseBallSpeed(double duration) {
    final ball = world.children.whereType<Ball>().firstOrNull;
    if (ball != null) {
      ball.velocity *= 1.5;
    }
    activatePowerUp('Increased Speed', Icons.speed, duration);
  }

  void activatePowerUp(String powerUpName, IconData icon, double duration) {
    final existingEffectIndex = activePowerUps.indexWhere((effect) => effect.name == powerUpName);

    if (existingEffectIndex != -1) {
      final existingEffect = activePowerUps[existingEffectIndex];
      existingEffect.duration = duration;
      existingEffect.timer?.cancel();
      existingEffect.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        existingEffect.duration -= 1;
        if (existingEffect.duration <= 0) {
          deactivatePowerUp(existingEffect);
          timer.cancel();
        }
      });
    } else {
      final effect = PowerUpEffect(powerUpName, icon, duration, 0.0, 1.0);
      activePowerUps.add(effect);

      effect.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        effect.duration -= 1;
        if (effect.duration <= 0) {
          deactivatePowerUp(effect);
          timer.cancel();
        }
      });
    }
  }

  void deactivatePowerUp(PowerUpEffect effect) {
    activePowerUps.remove(effect);
    effect.timer?.cancel();

    if (effect.name == 'Larger Bat') {
      final bat = world.children.whereType<Bat>().firstOrNull;
      if (bat != null) {
        bat.width = batDefault;
      }
    } else if (effect.name == 'Slow Ball' || effect.name == 'Increased Speed') {
      final ball = world.children.whereType<Ball>().firstOrNull;
      if (ball != null) {
        final initialSpeed = ball.initialVelocity.length;
        ball.velocity = ball.velocity.normalized() * initialSpeed;
      }
    } else if (effect.name == 'Fireball') {
  for (final ball in world.children.whereType<Ball>()) {
    ball.deactivateFireball();
  }
}
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const double initialSpacing = 50.0;
    const double fadeOutSpeed = 1.0 / initialSpacing;

    final double totalHeight = activePowerUps.length * initialSpacing;

    for (var i = 0; i < activePowerUps.length; i++) {
      final effect = activePowerUps[i];

      effect.yPosition -= fadeOutSpeed;
      effect.opacity = effect.duration / effect.initialDuration;

      if (effect.duration <= 0) {
        activePowerUps.removeAt(i);
        i--;
        continue;
      }

      final double centerY = (size.y - totalHeight) / 2 + i * initialSpacing + effect.yPosition;

      final namePainter = TextPainter(
        text: TextSpan(
          text: effect.name,
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(
              fontSize: 24,
              color: Colors.white.withOpacity(effect.opacity),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      namePainter.layout();
      final nameX = (size.x - namePainter.width) / 2;
      namePainter.paint(canvas, Offset(nameX, centerY));

      final durationPainter = TextPainter(
        text: TextSpan(
          text: '${effect.duration.toStringAsFixed(0)}s',
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(effect.opacity),
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      durationPainter.layout();
      final durationX = (size.x - durationPainter.width) / 2;
      final durationY = centerY + namePainter.height + 5;

      durationPainter.paint(canvas, Offset(durationX, durationY));
    }
  }

  void restartRound() {
    playState = PlayState.playing;
    world.removeAll(world.children.query<Ball>());

    final initialVelocity = Vector2(
      (rand.nextDouble() - 0.5) * width * 0.8,
      height * 0.3,
    ).normalized()..scale(height / 4);

    switch (selectedBallType) {
      case 'fast':
        world.add(FastBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      case 'heavy':
        world.add(HeavyBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      case 'bouncy':
        world.add(BouncyBall(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
        break;
      default:
        world.add(Ball(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: initialVelocity,
        ));
    }
  }

  void loseLife() {
    if (lives.value > 0) {
      lives.value--;
      if (lives.value == 0) {
        playState = PlayState.gameOver;
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          restartRound();
        });
      }
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    super.onTapUp(info);
    if (playState == PlayState.welcome || playState == PlayState.gameOver || playState == PlayState.won) {
      overlays.remove(playState.name);
      overlays.add('BallSelection');
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          world.children.query<Bat>().first.moveBy(-batStep);
          break;
        case LogicalKeyboardKey.arrowRight:
          world.children.query<Bat>().first.moveBy(batStep);
          break;
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.enter:
          if (playState == PlayState.welcome || playState == PlayState.gameOver || playState == PlayState.won) {
            overlays.add('BallSelection');
          }
          break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color.fromARGB(255, 32, 32, 32);
}