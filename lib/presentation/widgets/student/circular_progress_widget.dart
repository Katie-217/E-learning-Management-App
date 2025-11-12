// Circular progress widget
import 'package:flutter/material.dart';
import 'dart:math';

class CircularPercentWidget extends StatelessWidget {
  final double percent; // 0..1
  final String label;
  const CircularPercentWidget({super.key, required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120,120),
            painter: _CirclePainter(percent),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(percent*100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double pct;
  _CirclePainter(this.pct);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = min(size.width/2, size.height/2) - 6;
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final fgPaint = Paint()
      ..shader = SweepGradient(colors: [Colors.indigoAccent, Colors.deepPurpleAccent]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);
    final sweep = 2 * pi * pct;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) => old.pct != pct;
}

