import 'package:flutter/material.dart';

class TelegramLogo extends StatelessWidget {
  final double size;
  const TelegramLogo({Key? key, this.size = 20}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2AABEE),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _TelegramPlanePainter(),
        ),
      ),
    );
  }
}

class _TelegramPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    // Telegram paper plane path
    path.moveTo(w * 0.95, h * 0.05);
    path.lineTo(w * 0.05, h * 0.48);
    path.lineTo(w * 0.35, h * 0.65);
    path.lineTo(w * 0.78, h * 0.25);
    path.lineTo(w * 0.42, h * 0.70);
    path.lineTo(w * 0.40, h * 0.95);
    path.lineTo(w * 0.58, h * 0.78);
    path.lineTo(w * 0.85, h * 0.95);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
