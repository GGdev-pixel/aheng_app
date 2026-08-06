import 'package:flutter/material.dart';

class StreakFlameIcon extends StatelessWidget {
  final int streak;
  final double baseSize;

  const StreakFlameIcon({
    super.key,
    required this.streak,
    this.baseSize = 28,
  });

  Color get _color {
    if (streak >= 100) return const Color(0xFFFF3B30);
    if (streak >= 70) return const Color(0xFFFF5722);
    if (streak >= 50) return const Color(0xFFFF7A29);
    if (streak >= 20) return const Color(0xFFFF9800);
    if (streak >= 10) return const Color(0xFFFFB74D);
    return Colors.grey.shade400;
  }

  double get _size {
    if (streak >= 100) return baseSize * 1.5;
    if (streak >= 70) return baseSize * 1.35;
    if (streak >= 50) return baseSize * 1.25;
    if (streak >= 20) return baseSize * 1.15;
    if (streak >= 10) return baseSize * 1.05;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.local_fire_department,
      color: _color,
      size: _size,
    );

    if (streak >= 50) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.5),
              blurRadius: streak >= 100 ? 20 : 12,
              spreadRadius: streak >= 100 ? 3 : 1,
            ),
          ],
        ),
        child: icon,
      );
    }

    return icon;
  }
}