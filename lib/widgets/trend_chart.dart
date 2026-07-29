import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TrendChart extends StatelessWidget {
  final List<double> percentages;

  const TrendChart({super.key, required this.percentages});

  @override
  Widget build(BuildContext context) {
    if (percentages.length < 2) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text(
          'Qrafik üçün ən azı 2 test lazımdır',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(percentages),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> percentages;

  _TrendPainter(this.percentages);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()..color = AppColors.primaryBlue;

    const topPadding = 12.0;
    const bottomPadding = 12.0;
    final chartHeight = size.height - topPadding - bottomPadding;

    final n = percentages.length;
    final stepX = size.width / (n - 1);

    Offset pointAt(int i) {
      final x = stepX * i;
      final y = topPadding + chartHeight * (1 - percentages[i] / 100);
      return Offset(x, y);
    }

    // grid lines (25/50/75%)
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (final pct in [25, 50, 75]) {
      final y = topPadding + chartHeight * (1 - pct / 100);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < n; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fillPath.moveTo(p.dx, size.height);
        fillPath.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fillPath.lineTo(p.dx, p.dy);
      }
    }
    fillPath.lineTo(pointAt(n - 1).dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pointAt(i), 4, dotPaint);
      canvas.drawCircle(pointAt(i), 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.percentages != percentages;
  }
}