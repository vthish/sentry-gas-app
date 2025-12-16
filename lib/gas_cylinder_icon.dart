

import 'package:flutter/material.dart';

class GasCylinderIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GasCylinderIcon({
    super.key,
    this.size = 80.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GasCylinderPainter(color),
      ),
    );
  }
}

class _GasCylinderPainter extends CustomPainter {
  final Color color;

  _GasCylinderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.03;


    final RRect body = RRect.fromRectAndCorners(
      Rect.fromLTWH(width * 0.2, height * 0.2, width * 0.6, height * 0.7),
      topLeft: Radius.circular(width * 0.1),
      topRight: Radius.circular(width * 0.1),
      bottomLeft: Radius.circular(width * 0.05),
      bottomRight: Radius.circular(width * 0.05),
    );
    canvas.drawRRect(body, paint);
    canvas.drawRRect(body, borderPaint);


    final Rect neck = Rect.fromLTWH(width * 0.4, height * 0.1, width * 0.2, height * 0.1);
    canvas.drawRect(neck, paint);
    canvas.drawRect(neck, borderPaint);


    final RRect cap = RRect.fromRectAndCorners(
      Rect.fromLTWH(width * 0.35, height * 0.05, width * 0.3, height * 0.08),
      topLeft: Radius.circular(width * 0.05),
      topRight: Radius.circular(width * 0.05),
    );
    canvas.drawRRect(cap, paint);
    canvas.drawRRect(cap, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
