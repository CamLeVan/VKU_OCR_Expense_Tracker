import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailySpendingData {
  final String dayLabel;
  final double amount;

  DailySpendingData({
    required this.dayLabel,
    required this.amount,
  });
}

class WeeklyBarChart extends StatefulWidget {
  final List<DailySpendingData> weeklyData;

  const WeeklyBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredBarIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeklyData.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Chưa có dữ liệu tuần này', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final maxAmount = widget.weeklyData.map((e) => e.amount).fold(0.0, max);

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _BarChartPainter(
              weeklyData: widget.weeklyData,
              maxAmount: maxAmount > 0 ? maxAmount : 1.0,
              progress: _animation.value,
              hoveredIndex: _hoveredBarIndex,
              primaryColor: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DailySpendingData> weeklyData;
  final double maxAmount;
  final double progress;
  final int? hoveredIndex;
  final Color primaryColor;
  final Color textColor;

  _BarChartPainter({
    required this.weeklyData,
    required this.maxAmount,
    required this.progress,
    required this.hoveredIndex,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPadding = 30.0;
    const topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final barCount = weeklyData.length;
    final slotWidth = size.width / barCount;
    final barWidth = min(slotWidth * 0.55, 24.0);

    final baselinePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Draw grid horizontal lines
    for (int i = 1; i <= 3; i++) {
      final y = topPadding + (chartHeight * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw baseline
    final baselineY = size.height - bottomPadding;
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), baselinePaint);

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    final NumberFormat compactFormat = NumberFormat.compact(locale: 'vi_VN');

    // Draw bars
    for (int i = 0; i < barCount; i++) {
      final item = weeklyData[i];
      final isMax = item.amount == maxAmount && maxAmount > 0;
      final isHovered = hoveredIndex == i;

      final barHeight = (item.amount / maxAmount) * chartHeight * progress;
      final x = (i * slotWidth) + (slotWidth - barWidth) / 2;
      final y = baselineY - barHeight;

      final barRect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(
        barRect,
        const Radius.circular(6),
      );

      final barPaint = Paint()
        ..color = isMax
            ? Colors.deepOrangeAccent
            : isHovered
                ? primaryColor
                : primaryColor.withOpacity(0.75);

      canvas.drawRRect(rrect, barPaint);

      // Draw day label (T2, T3...)
      textPainter.text = TextSpan(
        text: item.dayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
          color: isMax ? Colors.deepOrangeAccent : textColor.withOpacity(0.7),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, baselineY + 8),
      );

      // Draw top value text for significant bars
      if (item.amount > 0 && progress > 0.8) {
        textPainter.text = TextSpan(
          text: compactFormat.format(item.amount),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isMax ? Colors.deepOrangeAccent : primaryColor,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (barWidth - textPainter.width) / 2, y - 16),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.maxAmount != maxAmount;
  }
}
