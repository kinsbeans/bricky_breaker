import 'package:flutter/material.dart';

class LivesDisplay extends StatelessWidget {
  final ValueNotifier<int> lives;

  const LivesDisplay({required this.lives, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: lives,
      builder: (context, lives, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: List.generate(
              lives,
              (index) => const Icon(Icons.favorite, color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
