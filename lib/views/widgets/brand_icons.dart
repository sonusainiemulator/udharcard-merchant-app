import 'package:flutter/material.dart';

/// Pixel-perfect 4-color Google "G" Logo
class GoogleBrandIcon extends StatelessWidget {
  final double size;
  const GoogleBrandIcon({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.42;
    final double strokeWidth = w * 0.20;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: radius,
    );

    // Blue Paint (#4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Green Paint (#34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Yellow Paint (#FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red Paint (#EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Arcs for 4 Google colors
    // Blue arc (top-right & middle bar)
    canvas.drawArc(rect, -0.4, 1.5, false, bluePaint);
    // Green arc (bottom)
    canvas.drawArc(rect, 1.1, 1.2, false, greenPaint);
    // Yellow arc (bottom-left)
    canvas.drawArc(rect, 2.3, 0.8, false, yellowPaint);
    // Red arc (top-left)
    canvas.drawArc(rect, 3.1, 1.3, false, redPaint);

    // Blue horizontal bar in middle
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.05, cy - strokeWidth / 2, w * 0.44, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pixel-perfect Apple Logo Icon
class AppleBrandIcon extends StatelessWidget {
  final double size;
  final Color color;
  const AppleBrandIcon({
    super.key,
    this.size = 22.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: size,
      color: color,
    );
  }
}

/// Pixel-perfect WhatsApp Logo Icon
class WhatsAppBrandIcon extends StatelessWidget {
  final double size;
  final Color color;
  const WhatsAppBrandIcon({
    super.key,
    this.size = 22.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chat_bubble_rounded,
      size: size,
      color: color,
    );
  }
}
