import 'package:flutter/material.dart';

class CameraCropOverlay extends StatelessWidget {
  const CameraCropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _CropOverlayPainter(),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Căn chỉnh hóa đơn vào khung hình',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.55);

    // Calculate crop rectangle in center of screen
    final rectWidth = size.width * 0.85;
    final rectHeight = size.height * 0.60;
    final rectLeft = (size.width - rectWidth) / 2;
    final rectTop = (size.height - rectHeight) / 2 - 20;

    final cropRect = Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);

    // Draw dark translucent overlay around crop rect
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw framing border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cropRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw prominent corner brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF6750A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final r = cropRect;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + cornerLength), Offset(r.left, r.top), cornerPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + cornerLength, r.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(r.right - cornerLength, r.top), Offset(r.right, r.top), cornerPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - cornerLength), Offset(r.left, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + cornerLength, r.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(r.right - cornerLength, r.bottom), Offset(r.right, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
