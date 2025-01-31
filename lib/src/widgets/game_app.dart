import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart';
import '../brick_breaker.dart';
import '../components/components.dart';
import '../config.dart';
import '../widgets/score_card.dart';
import '../widgets/lives.dart';
import '../widgets/overlay_screen.dart';
import '../widgets/ball_selection.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  late final BrickBreaker game;

  @override
  void initState() {
    super.initState();
    game = BrickBreaker();
  }

  void onBallSelected(String ballType) {
    setState(() {
      game.selectedBallType = ballType;
    });
  }

  void startGame() {
    game.startGame();
  }

  void resetGame() {
    setState(() {
      game.lives.value = 3;
      game.score.value = 0;
      game.activeBalls.value = 1;
      game.world.children.whereType<Ball>().forEach((ball) => ball.removeFromParent());
      game.playState = PlayState.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: const Color.fromARGB(255, 218, 218, 218),
          displayColor: const Color.fromARGB(255, 224, 224, 224),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 40, 43, 82),
                Color.fromARGB(255, 23, 13, 53),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Stack(
                  children: [
                    FittedBox(
                      child: SizedBox(
                        width: gameWidth,
                        height: gameHeight,
                        child: GameWidget<BrickBreaker>(
                          game: game,
                          overlayBuilderMap: {
                            PlayState.welcome.name: (context, game) => const OverlayScreen(
                              title: 'TAP TO PLAY',
                              subtitle: 'Use arrow keys or swipe',
                            ),
                            PlayState.gameOver.name: (context, game) => const OverlayScreen(
                              title: 'G A M E   O V E R',
                              subtitle: 'Tap to Play Again',
                            ),
                            PlayState.won.name: (context, game) => const OverlayScreen(
                              title: 'Y O U   W O N ! ! !',
                              subtitle: 'Tap to Play Again',
                            ),
                            'BallSelection': (context, game) => BallSelection(
                              onBallSelected: onBallSelected,
                              onPlay: startGame,
                            ),
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: LivesDisplay(lives: game.lives),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ScoreCard(score: game.score),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}