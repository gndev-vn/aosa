import 'dart:math' show cos, sin, pi;

import 'package:flutter/material.dart';
import '../../core/platform/app_platform.dart';

class AosaLoadingIndicator extends StatefulWidget {
  final double size;

  const AosaLoadingIndicator({super.key, this.size = 48});

  @override
  State<AosaLoadingIndicator> createState() => _AosaLoadingIndicatorState();
}

class _AosaLoadingIndicatorState extends State<AosaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppPlatformUtil.isAndroid16OrLater) {
      return _MaterialYouDots(size: widget.size, controller: _controller);
    }
    return _PulsingRing(size: widget.size, controller: _controller);
  }
}

class _MaterialYouDots extends StatelessWidget {
  final double size;
  final AnimationController controller;

  const _MaterialYouDots({required this.size, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dotSize = size * 0.15;
    final spacing = size * 0.08;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final phase = (controller.value - i * 0.25) % 1.0;
            final scale = 0.3 + 0.7 * (1 - (phase * 4 - 1).clamp(0, 1));
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withAlpha(
                          (255 * scale).toInt().clamp(80, 255),
                        ),
                        colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulsingRing extends StatelessWidget {
  final double size;
  final AnimationController controller;

  const _PulsingRing({required this.size, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: controller.value,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );

    final dotAngle = -pi / 2 + 2 * pi * progress;
    final dotX = center.dx + radius * cos(dotAngle);
    final dotY = center.dy + radius * sin(dotAngle);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(dotX, dotY), 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
