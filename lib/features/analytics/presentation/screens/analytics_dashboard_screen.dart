import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../../expenses/domain/models/expense_category.dart';
import '../../../expenses/domain/models/expense_model.dart';
import '../widgets/animated_pie_chart.dart';
import '../widgets/weekly_bar_chart.dart';

enum TimeFilter { allTime, thisMonth, thisWeek }

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimeFilter _selectedFilter = TimeFilter.allTime;
  bool _isLoading = true;

  Map<ExpenseCategory, double> _categoryTotals = {};
  List<DailySpendingData> _weeklySpendingData = [];

  double _totalSpend = 0.0;
  double _avgSpend = 0.0;
  int _transactionCount = 0;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final rows = await DatabaseHelper.instance.queryAllExpenses();
      final expenses = rows.map((r) => ExpenseModel.fromMap(r)).toList();

      // Apply time filter
      final now = DateTime.now();
      List<ExpenseModel> filteredExpenses;

      if (_selectedFilter == TimeFilter.thisMonth) {
        filteredExpenses = expenses.where((e) {
          return e.date.year == now.year && e.date.month == now.month;
        }).toList();
      } else if (_selectedFilter == TimeFilter.thisWeek) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filteredExpenses = expenses.where((e) {
          return e.date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        }).toList();
      } else {
        filteredExpenses = expenses;
      }

      // Calculate totals
      double total = 0.0;
      final Map<ExpenseCategory, double> categoryMap = {};

      for (var e in filteredExpenses) {
        total += e.amount;
        categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
      }

      // Build weekly spending data (Mon-Sun)
      final List<DailySpendingData> weeklyData = _buildWeeklyData(expenses);

      setState(() {
        _totalSpend = total;
        _transactionCount = filteredExpenses.length;
        _avgSpend = _transactionCount > 0 ? total / _transactionCount : 0.0;
        _categoryTotals = categoryMap;
        _weeklySpendingData = weeklyData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  List<DailySpendingData> _buildWeeklyData(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final Map<int, double> dayMap = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var e in expenses) {
      if (e.date.isAfter(monday.subtract(const Duration(days: 1))) &&
          e.date.isBefore(monday.add(const Duration(days: 7)))) {
        int weekday = e.date.weekday;
        dayMap[weekday] = (dayMap[weekday] ?? 0) + e.amount;
      }
    }

    final List<String> dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return List.generate(7, (index) {
      return DailySpendingData(
        dayLabel: dayNames[index],
        amount: dayMap[index + 1] ?? 0.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Tích Chi Tiêu (Analytics)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalyticsData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Filter Segmented Buttons
                    Center(
                      child: SegmentedButton<TimeFilter>(
                        segments: const [
                          ButtonSegment(
                            value: TimeFilter.allTime,
                            label: Text('Tất cả'),
                            icon: Icon(Icons.all_inclusive_rounded),
                          ),
                          ButtonSegment(
                            value: TimeFilter.thisMonth,
                            label: Text('Tháng này'),
                            icon: Icon(Icons.calendar_month_rounded),
                          ),
                          ButtonSegment(
                            value: TimeFilter.thisWeek,
                            label: Text('Tuần này'),
                            icon: Icon(Icons.view_week_rounded),
                          ),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (set) {
                          setState(() {
                            _selectedFilter = set.first;
                          });
                          _loadAnalyticsData();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Key Financial KPIs Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            title: 'Tổng Chi',
                            value: _currencyFormat.format(_totalSpend),
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _KpiCard(
                            title: 'Số Giao Dịch',
                            value: '$_transactionCount đơn',
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _KpiCard(
                            title: 'Trung Bình',
                            value: _currencyFormat.format(_avgSpend),
                            icon: Icons.analytics_rounded,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Category Distribution Pie Chart
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phân Phối Chi Tiêu',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'CustomPainter',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedPieChart(
                              categoryTotals: _categoryTotals,
                              totalAmount: _totalSpend,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card 2: Weekly Spending Bar Chart
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Xu Hướng Chi Tiêu Tuần Này',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Canvas Chart',
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            WeeklyBarChart(
                              weeklyData: _weeklySpendingData,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
