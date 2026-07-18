import 'package:flutter/material.dart';

class OverlayPainter extends CustomPainter {
  final RRect scanRect;
  final Color color;

  const OverlayPainter({required this.scanRect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outer = RRect.fromRectAndRadius(outerRect, Radius.zero);
    final path = Path()
      ..addRRect(outer)
      ..addRRect(scanRect);
    canvas.drawPath(
      Path.combine(
          PathOperation.reverseDifference, path, Path()..addRRect(scanRect)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(OverlayPainter old) =>
      old.scanRect != scanRect || old.color != color;
}
