import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BallSelection extends StatefulWidget {
  final Function(String) onBallSelected;
  final VoidCallback onPlay;

  const BallSelection({required this.onBallSelected, required this.onPlay, super.key});

  @override
  BallSelectionState createState() => BallSelectionState();
}

class BallSelectionState extends State<BallSelection> with SingleTickerProviderStateMixin {
  String? selectedBallType;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectBall(String ballType) {
    setState(() {
      selectedBallType = ballType;
    });
    widget.onBallSelected(ballType);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 32, 32, 32),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select a Ball', style: GoogleFonts.pressStart2p(textStyle: Theme.of(context).textTheme.headlineMedium)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBallOption(context, 'Default', Colors.grey, 'default'),
              _buildBallOption(context, 'Fast', Colors.red, 'fast'),
              _buildBallOption(context, 'Sticky', Colors.blue, 'heavy'),
              _buildBallOption(context, 'Bouncy', Colors.green, 'bouncy'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Preview', style: GoogleFonts.pressStart2p(textStyle: Theme.of(context).textTheme.headlineSmall)),
          const SizedBox(height: 10),
          _buildBallPreview(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectedBallType == null ? null : widget.onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('Play', style: GoogleFonts.pressStart2p(textStyle: Theme.of(context).textTheme.labelLarge)),
          ),
        ],
      ),
    );
  }

  Widget _buildBallOption(BuildContext context, String label, Color color, String ballType) {
    return GestureDetector(
      onTap: () => selectBall(ballType),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: selectedBallType == ballType ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              child: selectedBallType == ballType ? const Icon(Icons.check, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: GoogleFonts.pressStart2p(textStyle: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildBallPreview() {
    if (selectedBallType == null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color.fromARGB(31, 212, 212, 212),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Ball Preview Here',
            style: TextStyle(color: Color.fromARGB(115, 212, 212, 212)),
          ),
        ),
      );
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: BallPreviewPainter(selectedBallType!, _controller.value),
          );
        },
      ),
    );
  }
}

class BallPreviewPainter extends CustomPainter {
  final String ballType;
  final double progress;

  BallPreviewPainter(this.ballType, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    double speed = 1.0;

    switch (ballType) {
      case 'fast':
        paint.color = Colors.red;
        speed = 2.0;
        break;
      case 'heavy':
        paint.color = Colors.blue;
        speed = 0.5;
        break;
      case 'bouncy':
        paint.color = Colors.green;
        speed = 3.0;
        break;
      default:
        paint.color = Colors.grey;
    }

    final double x = (progress * size.width * speed) % size.width;
    final double y = (progress * size.height * speed) % size.height;

    canvas.drawCircle(Offset(x, y), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
