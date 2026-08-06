import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    final random = Random();
    final colors = [
      AppColors.primaryBlue,
      AppColors.accentRed,
      Colors.amber,
      Colors.white,
    ];

    _particles = List.generate(45, (i) {
      return _Particle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.3,
        size: 6 + random.nextDouble() * 8,
        color: colors[random.nextInt(colors.length)],
        horizontalDrift: (random.nextDouble() - 0.5) * 0.6,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
        isCircle: random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double delay;
  final double size;
  final Color color;
  final double horizontalDrift;
  final double rotationSpeed;
  final bool isCircle;

  _Particle({
    required this.x,
    required this.delay,
    required this.size,
    required this.color,
    required this.horizontalDrift,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localProgress = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final startY = size.height * 0.35;
      final fallDistance = size.height * 0.55;
      final y = startY + fallDistance * Curves.easeIn.transform(localProgress);
      final x = size.width * p.x + (size.width * p.horizontalDrift * localProgress);

      final opacity = localProgress > 0.75
          ? (1 - (localProgress - 0.75) / 0.25).clamp(0.0, 1.0)
          : 1.0;

      final paint = Paint()..color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * localProgress * pi);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}