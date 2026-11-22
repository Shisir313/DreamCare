import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DermiState {
  idle,
  talking,
  listening,
  happy,
  thinking,
}

/// Cute interactive Dermi Mascot Character
/// Features anime-style glistening eyes, animated blinking, mouth movements,
/// soft bouncing, leaf sprout swaying, rosy blush cheeks, and tap interactivity.
class DermiCharacter extends StatefulWidget {
  final DermiState state;
  final double size;
  final VoidCallback? onTap;
  final bool enableInteraction;

  const DermiCharacter({
    super.key,
    this.state = DermiState.idle,
    this.size = 200,
    this.onTap,
    this.enableInteraction = true,
  });

  @override
  State<DermiCharacter> createState() => _DermiCharacterState();
}

class _DermiCharacterState extends State<DermiCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _mouthController;
  late AnimationController _sproutController;
  late AnimationController _squishController;
  late AnimationController _sparkleController;

  bool _isBlinking = false;
  Timer? _blinkTimer;
  bool _isTappedSquishing = false;

  @override
  void initState() {
    super.initState();

    // Floating bobbing motion
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Mouth movement during talking
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Cute leaf sprout sway
    _sproutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Tap squish bounce
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Ambient sparkle animation
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startBlinkingLoop();
    _handleStateChange(widget.state);
  }

  void _startBlinkingLoop() {
    _blinkTimer?.cancel();
    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    final nextBlinkMs = 2600 + math.Random().nextInt(2200);
    _blinkTimer = Timer(Duration(milliseconds: nextBlinkMs), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);
        _scheduleNextBlink();
      });
    });
  }

  @override
  void didUpdateWidget(covariant DermiCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateChange(widget.state);
    }
  }

  void _handleStateChange(DermiState state) {
    if (state == DermiState.talking) {
      _mouthController.repeat(reverse: true);
    } else {
      _mouthController.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bobController.dispose();
    _mouthController.dispose();
    _sproutController.dispose();
    _squishController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enableInteraction) return;

    HapticFeedback.lightImpact();
    setState(() => _isTappedSquishing = true);
    _squishController.forward(from: 0).then((_) {
      if (mounted) setState(() => _isTappedSquishing = false);
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.size;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bobController,
          _mouthController,
          _sproutController,
          _squishController,
          _sparkleController,
        ]),
        builder: (context, child) {
          // Calculate animated parameters
          final bobY = math.sin(_bobController.value * math.pi) * 8.0;
          final sproutAngle =
              math.sin(_sproutController.value * math.pi * 2) * 0.12;
          final mouthOpen = _mouthController.value;

          // Squish scale: compress then bounce out
          double scaleX = 1.0;
          double scaleY = 1.0;
          if (_isTappedSquishing) {
            final t = _squishController.value;
            final squish = math.sin(t * math.pi) * 0.15;
            scaleX = 1.0 + squish;
            scaleY = 1.0 - squish;
          } else if (widget.state == DermiState.happy) {
            final happyBounce = math.sin(_bobController.value * math.pi * 3) * 0.08;
            scaleX = 1.0 - happyBounce * 0.5;
            scaleY = 1.0 + happyBounce;
          }

          return SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Listening ambient pulse glow rings
                if (widget.state == DermiState.listening)
                  _buildListeningAura(effectiveSize),

                // Floating character body with animations
                Transform.translate(
                  offset: Offset(0, -bobY),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    alignment: Alignment.bottomCenter,
                    child: CustomPaint(
                      size: Size(effectiveSize, effectiveSize),
                      painter: _DermiMascotPainter(
                        state: widget.state,
                        isBlinking: _isBlinking,
                        mouthOpen: mouthOpen,
                        sproutAngle: sproutAngle,
                        sparklePhase: _sparkleController.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListeningAura(double size) {
    return AnimatedBuilder(
      animation: _bobController,
      builder: (context, _) {
        final progress = _bobController.value;
        return Container(
          width: size * (1.0 + progress * 0.28),
          height: size * (1.0 + progress * 0.28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4A7C59).withOpacity(0.35 * (1.0 - progress)),
                const Color(0xFF68C28E).withOpacity(0.15 * (1.0 - progress)),
                Colors.transparent,
              ],
              stops: const [0.4, 0.75, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Painter for the Dewy Chibi Mascot "Dermi"
class _DermiMascotPainter extends CustomPainter {
  final DermiState state;
  final bool isBlinking;
  final double mouthOpen;
  final double sproutAngle;
  final double sparklePhase;

  _DermiMascotPainter({
    required this.state,
    required this.isBlinking,
    required this.mouthOpen,
    required this.sproutAngle,
    required this.sparklePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.54);
    final radius = w * 0.36;

    // 1. Soft Shadow Underneath
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, h * 0.92),
        width: radius * 1.5,
        height: radius * 0.28,
      ),
      shadowPaint,
    );

    // 2. Botanical Leaf Sprout on Head
    _drawSprout(canvas, center, radius, sproutAngle);

    // 3. Mascot Droplet Body
    _drawBody(canvas, center, radius);

    // 4. Glossy 3D Highlight (Dewy glass-skin look)
    _drawGlossHighlight(canvas, center, radius);

    // 5. Rosy Cheeks
    _drawCheeks(canvas, center, radius);

    // 6. Glistening Anime Eyes
    _drawEyes(canvas, center, radius);

    // 7. Cute Mouth
    _drawMouth(canvas, center, radius);

    // 8. Magical Sparkles
    _drawSparkles(canvas, size, center, radius);
  }

  void _drawSprout(Canvas canvas, Offset center, double radius, double angle) {
    canvas.save();
    final sproutBase = Offset(center.dx, center.dy - radius * 0.95);
    canvas.translate(sproutBase.dx, sproutBase.dy);
    canvas.rotate(angle);

    final stemPaint = Paint()
      ..color = const Color(0xFF2E633C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.07
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(radius * 0.04, -radius * 0.25, 0, -radius * 0.36);
    canvas.drawPath(stemPath, stemPaint);

    // Left leaf
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8CE09D), Color(0xFF387A49)],
      ).createShader(Rect.fromLTWH(-radius * 0.35, -radius * 0.5, radius * 0.7, radius * 0.5))
      ..style = PaintingStyle.fill;

    final leftLeaf = Path()
      ..moveTo(0, -radius * 0.32)
      ..quadraticBezierTo(-radius * 0.28, -radius * 0.42, -radius * 0.30, -radius * 0.22)
      ..quadraticBezierTo(-radius * 0.15, -radius * 0.18, 0, -radius * 0.28);
    canvas.drawPath(leftLeaf, leafPaint);

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(0, -radius * 0.32)
      ..quadraticBezierTo(radius * 0.28, -radius * 0.42, radius * 0.30, -radius * 0.22)
      ..quadraticBezierTo(radius * 0.15, -radius * 0.18, 0, -radius * 0.28);
    canvas.drawPath(rightLeaf, leafPaint);

    canvas.restore();
  }

  void _drawBody(Canvas canvas, Offset center, double radius) {
    final bodyPath = Path();

    // Cute chubby droplet / teardrop shape
    final topPoint = Offset(center.dx, center.dy - radius * 0.98);
    final botCenter = Offset(center.dx, center.dy + radius * 0.2);

    bodyPath.moveTo(topPoint.dx, topPoint.dy);
    // Right curve down
    bodyPath.cubicTo(
      center.dx + radius * 0.65,
      center.dy - radius * 0.45,
      center.dx + radius * 1.08,
      botCenter.dy + radius * 0.35,
      center.dx,
      botCenter.dy + radius * 0.82,
    );
    // Left curve up
    bodyPath.cubicTo(
      center.dx - radius * 1.08,
      botCenter.dy + radius * 0.35,
      center.dx - radius * 0.65,
      center.dy - radius * 0.45,
      topPoint.dx,
      topPoint.dy,
    );
    bodyPath.close();

    // Dynamic Gradient based on state
    Color topColor = const Color(0xFF76C590);
    Color botColor = const Color(0xFF427B55);

    if (state == DermiState.listening) {
      topColor = const Color(0xFF5ED8B6);
      botColor = const Color(0xFF2C7D6B);
    } else if (state == DermiState.happy) {
      topColor = const Color(0xFF8AE0A0);
      botColor = const Color(0xFF47885A);
    } else if (state == DermiState.thinking) {
      topColor = const Color(0xFF70C5AA);
      botColor = const Color(0xFF386E64);
    }

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: [
          topColor,
          botColor,
          const Color(0xFF274D34),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1))
      ..style = PaintingStyle.fill;

    canvas.drawPath(bodyPath, bodyPaint);

    // Inner rim glow for soft depth
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04;
    canvas.drawPath(bodyPath, rimPaint);
  }

  void _drawGlossHighlight(Canvas canvas, Offset center, double radius) {
    // 3D glassy reflection on upper left
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx - radius * 0.38, center.dy - radius * 0.36);
    canvas.rotate(-0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.34,
        height: radius * 0.16,
      ),
      glossPaint,
    );
    canvas.restore();

    // Secondary tiny dot highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.48, center.dy - radius * 0.18),
      radius * 0.05,
      Paint()..color = Colors.white.withOpacity(0.28),
    );
  }

  void _drawCheeks(Canvas canvas, Offset center, double radius) {
    final blushColor = (state == DermiState.happy || state == DermiState.talking)
        ? const Color(0xFFFF7A93).withOpacity(0.70)
        : const Color(0xFFFF8FA5).withOpacity(0.55);

    final blushPaint = Paint()
      ..color = blushColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    final cheekY = center.dy + radius * 0.22;
    final cheekSpacing = radius * 0.52;

    // Left cheek
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - cheekSpacing, cheekY),
        width: radius * 0.24,
        height: radius * 0.15,
      ),
      blushPaint,
    );

    // Right cheek
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + cheekSpacing, cheekY),
        width: radius * 0.24,
        height: radius * 0.15,
      ),
      blushPaint,
    );
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final eyeY = center.dy + radius * 0.06;
    final eyeSpacing = radius * 0.34;
    final leftEyeCenter = Offset(center.dx - eyeSpacing, eyeY);
    final rightEyeCenter = Offset(center.dx + eyeSpacing, eyeY);

    if (isBlinking) {
      // Blinking: cute curved lines
      _drawBlinkLine(canvas, leftEyeCenter, radius);
      _drawBlinkLine(canvas, rightEyeCenter, radius);
      return;
    }

    if (state == DermiState.happy) {
      // Happy eyes: ^‿^
      _drawHappyEye(canvas, leftEyeCenter, radius);
      _drawHappyEye(canvas, rightEyeCenter, radius);
      return;
    }

    // Standard / Glistening Chibi Eyes
    final eyeRadius = radius * 0.17;
    final darkEyePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF132A1C), Color(0xFF0A170F)],
      ).createShader(Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius))
      ..style = PaintingStyle.fill;

    // Pupil shift for thinking
    Offset pupilOffset = Offset.zero;
    if (state == DermiState.thinking) {
      pupilOffset = Offset(radius * 0.04, -radius * 0.05);
    }

    // Left eye base
    canvas.drawCircle(leftEyeCenter, eyeRadius, darkEyePaint);
    // Right eye base
    canvas.drawCircle(rightEyeCenter, eyeRadius, darkEyePaint);

    // White Sparkling Catchlights
    final bigCatchlightPaint = Paint()..color = Colors.white;
    final smallCatchlightPaint = Paint()..color = Colors.white.withOpacity(0.85);

    // Catchlight offsets
    final bigOffset = Offset(-eyeRadius * 0.32, -eyeRadius * 0.32) + pupilOffset;
    final smallOffset = Offset(eyeRadius * 0.38, eyeRadius * 0.34) + pupilOffset;

    // Left eye catchlights
    canvas.drawCircle(leftEyeCenter + bigOffset, eyeRadius * 0.38, bigCatchlightPaint);
    canvas.drawCircle(leftEyeCenter + smallOffset, eyeRadius * 0.20, smallCatchlightPaint);

    // Right eye catchlights
    canvas.drawCircle(rightEyeCenter + bigOffset, eyeRadius * 0.38, bigCatchlightPaint);
    canvas.drawCircle(rightEyeCenter + smallOffset, eyeRadius * 0.20, smallCatchlightPaint);
  }

  void _drawBlinkLine(Canvas canvas, Offset eyeCenter, double radius) {
    final blinkPaint = Paint()
      ..color = const Color(0xFF1A3823)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(eyeCenter.dx - radius * 0.14, eyeCenter.dy)
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeCenter.dy + radius * 0.07,
        eyeCenter.dx + radius * 0.14,
        eyeCenter.dy,
      );
    canvas.drawPath(path, blinkPaint);
  }

  void _drawHappyEye(Canvas canvas, Offset eyeCenter, double radius) {
    final happyPaint = Paint()
      ..color = const Color(0xFF15331E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(eyeCenter.dx - radius * 0.15, eyeCenter.dy + radius * 0.04)
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeCenter.dy - radius * 0.11,
        eyeCenter.dx + radius * 0.15,
        eyeCenter.dy + radius * 0.04,
      );
    canvas.drawPath(path, happyPaint);
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthCenter = Offset(center.dx, center.dy + radius * 0.34);

    if (state == DermiState.talking) {
      // Animated opening/closing mouth with cute tongue
      final openH = radius * (0.08 + mouthOpen * 0.16);
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: radius * 0.24,
        height: openH,
      );

      // Dark mouth interior
      final mouthBg = Paint()..color = const Color(0xFF702030);
      canvas.drawRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(12)), mouthBg);

      // Pink cute tongue inside
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(12)));
      final tonguePaint = Paint()..color = const Color(0xFFFF859B);
      canvas.drawCircle(
        Offset(mouthCenter.dx, mouthCenter.dy + openH * 0.35),
        radius * 0.10,
        tonguePaint,
      );
      canvas.restore();
      return;
    }

    if (state == DermiState.thinking) {
      // Cute round "o" mouth
      final oPaint = Paint()
        ..color = const Color(0xFF1A3823)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.045;
      canvas.drawCircle(mouthCenter, radius * 0.06, oPaint);
      return;
    }

    // Default & Happy: cute cat / curved smile
    final mouthPaint = Paint()
      ..color = const Color(0xFF1A3823)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..moveTo(mouthCenter.dx - radius * 0.11, mouthCenter.dy)
      ..quadraticBezierTo(
        mouthCenter.dx,
        mouthCenter.dy + (state == DermiState.happy ? radius * 0.12 : radius * 0.07),
        mouthCenter.dx + radius * 0.11,
        mouthCenter.dy,
      );
    canvas.drawPath(smilePath, mouthPaint);
  }

  void _drawSparkles(Canvas canvas, Size size, Offset center, double radius) {
    // 3 animated sparkles orbiting Dermi
    final p = sparklePhase * 2 * math.pi;

    _drawSingleStar(
      canvas,
      Offset(center.dx + radius * 0.95, center.dy - radius * 0.70 + math.sin(p) * 6),
      radius * (0.10 + math.sin(p) * 0.03),
      const Color(0xFFFFF7C2),
    );

    _drawSingleStar(
      canvas,
      Offset(center.dx - radius * 0.90, center.dy + radius * 0.50 + math.cos(p) * 6),
      radius * (0.08 + math.cos(p) * 0.02),
      const Color(0xFFE2FADB),
    );

    if (state == DermiState.happy) {
      _drawSingleStar(
        canvas,
        Offset(center.dx + radius * 0.75, center.dy + radius * 0.75 + math.sin(p + 1) * 8),
        radius * 0.11,
        const Color(0xFFFFD4E2),
      );
    }
  }

  void _drawSingleStar(Canvas canvas, Offset c, double r, Color color) {
    if (r <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DermiMascotPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.mouthOpen != mouthOpen ||
        oldDelegate.sproutAngle != sproutAngle ||
        oldDelegate.sparklePhase != sparklePhase;
  }
}

/// Compact circular avatar of Dermi (for FAB, AppBars, and Chat)
class DermiAvatar extends StatelessWidget {
  final double radius;
  final DermiState state;
  final VoidCallback? onTap;

  const DermiAvatar({
    super.key,
    this.radius = 22,
    this.state = DermiState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF8CE09D), Color(0xFF387A49)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A7C59).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Transform.scale(
            scale: 1.35,
            alignment: const Alignment(0, 0.15),
            child: DermiCharacter(
              size: radius * 2,
              state: state,
              enableInteraction: false,
            ),
          ),
        ),
      ),
    );
  }
}
