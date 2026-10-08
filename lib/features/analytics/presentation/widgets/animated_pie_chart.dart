import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../expenses/domain/models/expense_category.dart';

class CategoryPieData {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  CategoryPieData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class AnimatedPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;

  const AnimatedPieChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  final NumberFormat _currencyFormat = NumberFormat.compact(locale: 'vi_VN');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CategoryPieData> get _pieDataList {
    if (widget.totalAmount <= 0) return [];
    return widget.categoryTotals.entries.map((entry) {
      return CategoryPieData(
        category: entry.key,
        amount: entry.value,
        percentage: (entry.value / widget.totalAmount) * 100,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pieData = _pieDataList;

    if (pieData.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu chi tiêu',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _PieChartPainter(
                  pieData: pieData,
                  totalAmount: widget.totalAmount,
                  progress: _animation.value,
                  selectedIndex: _selectedIndex,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedIndex != null
                            ? pieData[_selectedIndex!].category.displayName
                            : 'Tổng chi tiêu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedIndex != null
                            ? '${_currencyFormat.format(pieData[_selectedIndex!].amount)} đ'
                            : '${_currencyFormat.format(widget.totalAmount)} đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedIndex != null)
                        Text(
                          '${pieData[_selectedIndex!].percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(pieData[_selectedIndex!].category.colorHex),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Category Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(pieData.length, (index) {
            final item = pieData[index];
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = isSelected ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(item.category.colorHex).withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: Color(item.category.colorHex),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.category.iconEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      item.category.displayName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<CategoryPieData> pieData;
  final double totalAmount;
  final double progress;
  final int? selectedIndex;
  final Color textColor;

  _PieChartPainter({
    required this.pieData,
    required this.totalAmount,
    required this.progress,
    required this.selectedIndex,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;
    const strokeWidth = 32.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2; // Start from top 12 o'clock

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final totalSweepAngle = 2 * pi * progress;
    double currentSweep = 0;

    for (int i = 0; i < pieData.length; i++) {
      final item = pieData[i];
      final sweepAngle = (item.amount / totalAmount) * 2 * pi;

      if (currentSweep + sweepAngle > totalSweepAngle) {
        final remainingSweep = totalSweepAngle - currentSweep;
        if (remainingSweep > 0) {
          _drawSlice(canvas, rect, startAngle, remainingSweep, item, i == selectedIndex, paint);
        }
        break;
      } else {
        _drawSlice(canvas, rect, startAngle, sweepAngle, item, i == selectedIndex, paint);
        startAngle += sweepAngle;
        currentSweep += sweepAngle;
      }
    }
  }

  void _drawSlice(
    Canvas canvas,
    Rect rect,
    double startAngle,
    double sweepAngle,
    CategoryPieData item,
    bool isSelected,
    Paint paint,
  ) {
    paint.color = Color(item.category.colorHex);
    paint.strokeWidth = isSelected ? 38.0 : 32.0;

    if (isSelected) {
      // Draw highlighted offset slice
      final midAngle = startAngle + sweepAngle / 2;
      const offsetDistance = 6.0;
      final dx = cos(midAngle) * offsetDistance;
      final dy = sin(midAngle) * offsetDistance;
      final offsetRect = rect.shift(Offset(dx, dy));
      canvas.drawArc(offsetRect, startAngle, sweepAngle - 0.03, false, paint);
    } else {
      canvas.drawArc(rect, startAngle, sweepAngle - 0.03, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.totalAmount != totalAmount;
  }
}
