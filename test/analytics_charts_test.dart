import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_3_ocr_expense_tracker/features/analytics/presentation/widgets/animated_pie_chart.dart';
import 'package:mini_project_3_ocr_expense_tracker/features/analytics/presentation/widgets/weekly_bar_chart.dart';
import 'package:mini_project_3_ocr_expense_tracker/features/expenses/domain/models/expense_category.dart';

void main() {
  group('CustomPainter Charts Widget Tests', () {
    testWidgets('AnimatedPieChart renders correctly with data', (WidgetTester tester) async {
      final categoryTotals = {
        ExpenseCategory.food: 150000.0,
        ExpenseCategory.study: 50000.0,
        ExpenseCategory.travel: 30000.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPieChart(
              categoryTotals: categoryTotals,
              totalAmount: 230000.0,
            ),
          ),
        ),
      );

      // Verify widget builds without error
      expect(find.byType(AnimatedPieChart), findsOneWidget);
      expect(find.text('Tổng chi tiêu'), findsOneWidget);

      // Fast forward animation
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('AnimatedPieChart renders empty state when total is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPieChart(
              categoryTotals: {},
              totalAmount: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Chưa có dữ liệu chi tiêu'), findsOneWidget);
    });

    testWidgets('WeeklyBarChart renders CustomPaint canvas without throwing layout errors', (WidgetTester tester) async {
      final weeklyData = [
        DailySpendingData(dayLabel: 'T2', amount: 50000),
        DailySpendingData(dayLabel: 'T3', amount: 120000),
        DailySpendingData(dayLabel: 'T4', amount: 0),
        DailySpendingData(dayLabel: 'T5', amount: 80000),
        DailySpendingData(dayLabel: 'T6', amount: 45000),
        DailySpendingData(dayLabel: 'T7', amount: 200000),
        DailySpendingData(dayLabel: 'CN', amount: 30000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(
              weeklyData: weeklyData,
            ),
          ),
        ),
      );

      expect(find.byType(WeeklyBarChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpAndSettle();
    });
  });
}
