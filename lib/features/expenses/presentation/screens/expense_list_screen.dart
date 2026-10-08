import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../ocr_scanner/presentation/screens/camera_scanner_screen.dart';
import '../../data/expense_export_service.dart';
import '../../domain/models/expense_model.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;

  final ExpenseExportService _exportService = ExpenseExportService();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final rows = await DatabaseHelper.instance.queryAllExpenses();
      final loaded = rows.map((r) => ExpenseModel.fromMap(r)).toList();
      setState(() {
        _expenses = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final file = await _exportService.exportExpensesToCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📊 Đã xuất file CSV thành công:\n${file.path}'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất file CSV: $e')),
        );
      }
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này khỏi CSDL?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteExpense(id);
      _loadExpenses();
    }
  }

  void _openCameraScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CameraScannerScreen()),
    );
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Thu Chi (Receipt OCR)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: _exportCsv,
            tooltip: 'Xuất dữ liệu ra CSV / Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadExpenses,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bấm nút bên dưới để quét hóa đơn bằng AI OCR',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _openCameraScanner,
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Quét Hóa Đơn Ngay'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _expenses.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemBuilder: (context, index) {
                      final item = _expenses[index];
                      return ExpenseCard(
                        expense: item,
                        onDelete: () {
                          if (item.id != null) {
                            _deleteExpense(item.id!);
                          }
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCameraScanner,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Quét Hóa Đơn'),
      ),
    );
  }
}
