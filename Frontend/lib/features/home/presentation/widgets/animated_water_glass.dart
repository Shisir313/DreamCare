import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:math';

class AnimatedWaterGlass extends StatefulWidget {
  final int current;
  final int total;
  final VoidCallback onTap;

  const AnimatedWaterGlass({
    super.key,
    required this.current,
    required this.total,
    required this.onTap,
  });

  @override
  State<AnimatedWaterGlass> createState() => _AnimatedWaterGlassState();
}

class _AnimatedWaterGlassState extends State<AnimatedWaterGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _previousProgress = widget.current / widget.total;
    _fillAnimation = Tween<double>(
      begin: _previousProgress,
      end: _previousProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedWaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _updateAnimation();
      if (widget.current > oldWidget.current) {
        _playSound();
        _vibrate();
      }
    }
  }

  void _updateAnimation() {
    final newValue = widget.current / widget.total;

    _fillAnimation = Tween<double>(
      begin: _previousProgress,
      end: newValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _previousProgress = newValue;
    _controller.forward(from: 0);
  }

  Future<void> _playSound() async {
    try {
      // Play a simple tap sound (we'll use system sound for now)
      // You can add custom sound file later
      await _audioPlayer.play(AssetSource('sounds/water_drop.mp3'));
    } catch (e) {
      print('Could not play sound: $e');
    }
  }

  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      print('Could not vibrate: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _fillAnimation,
        builder: (context, child) {
          return Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Water fill
                  FractionallySizedBox(
                    heightFactor: _fillAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary
                                .withOpacity(0.6),
                            Theme.of(context).colorScheme.primary,
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: WavePainter(
                          animation: _controller,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  // Text overlay
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.current}',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: _fillAnimation.value > 0.5
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'of ${widget.total} glasses',
                          style: TextStyle(
                            color: _fillAnimation.value > 0.5
                                ? Colors.white70
                                : Theme.of(context).colorScheme.primary
                                      .withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${((widget.current / widget.total) * 100).toInt()}%',
                          style: TextStyle(
                            color: _fillAnimation.value > 0.5
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tap hint (only when empty)
                  if (widget.current == 0)
                    Positioned(
                      bottom: 20,
                      child:
                          Text(
                                'Tap to add water 💧',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary
                                      .withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .fadeIn(duration: 1000.ms)
                              .then()
                              .fadeOut(duration: 1000.ms),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Wave animation painter
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 10.0;
    final waveLength = size.width / 2;

    path.moveTo(0, waveHeight * 2);

    for (double i = 0; i <= size.width; i++) {
      final waveY =
          waveHeight *
              sin((i / waveLength * 2 * pi) + (animation.value * 2 * pi)) +
          waveHeight;
      path.lineTo(i, waveY);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
