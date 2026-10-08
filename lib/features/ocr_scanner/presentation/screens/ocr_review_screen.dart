import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../../expenses/domain/models/expense_category.dart';
import '../../../expenses/domain/models/expense_model.dart';
import '../../domain/models/parsed_receipt.dart';

class OcrReviewScreen extends StatefulWidget {
  final String imagePath;
  final ParsedReceipt parsedReceipt;

  const OcrReviewScreen({
    super.key,
    required this.imagePath,
    required this.parsedReceipt,
  });

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  bool _showRawText = false;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();

    // Pre-fill fields from Regex Heuristic Parser result
    final initialMerchant = widget.parsedReceipt.merchant ?? 'Siêu thị / Quán ăn';
    final initialAmount = widget.parsedReceipt.totalAmount ?? 0.0;
    _selectedDate = widget.parsedReceipt.date ?? DateTime.now();

    _merchantController = TextEditingController(text: initialMerchant);
    _amountController = TextEditingController(
      text: initialAmount > 0 ? _currencyFormat.format(initialAmount) : '',
    );
    _dateController = TextEditingController(
      text: _dateFormat.format(_selectedDate),
    );

    // Auto-detect category based on merchant keywords
    _autoDetectCategory(initialMerchant);
  }

  void _autoDetectCategory(String merchant) {
    final lower = merchant.toLowerCase();
    if (lower.contains('co.op') || lower.contains('winmart') || lower.contains('coffee') || lower.contains('food') || lower.contains('cơm')) {
      _selectedCategory = ExpenseCategory.food;
    } else if (lower.contains('book') || lower.contains('sách') || lower.contains('photo') || lower.contains('vku')) {
      _selectedCategory = ExpenseCategory.study;
    } else if (lower.contains('grab') || lower.contains('xăng') || lower.contains('petro') || lower.contains('xe')) {
      _selectedCategory = ExpenseCategory.travel;
    } else if (lower.contains('phong vũ') || lower.contains('gear') || lower.contains('tgdd') || lower.contains('fpt')) {
      _selectedCategory = ExpenseCategory.gear;
    } else if (lower.contains('cgv') || lower.contains('lotte') || lower.contains('game')) {
      _selectedCategory = ExpenseCategory.entertainment;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse amount string back to double
      String cleanAmountStr = _amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '');
      double amount = double.tryParse(cleanAmountStr) ?? 0.0;

      final newExpense = ExpenseModel(
        title: _merchantController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        imagePath: widget.imagePath,
      );

      // Save to SQLite local database
      await DatabaseHelper.instance.insertExpense(newExpense.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đã lưu giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to Root/Home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu vào CSDL: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Nhận Kết Quả OCR'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt Image Thumbnail Card
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.black12,
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ML Kit OCR Scanned',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Thông Tin Chi Tiêu (Đã bóc tách tự động)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Merchant Name Field
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Tên Cửa Hàng / Nội Dung',
                    prefixIcon: Icon(Icons.storefront_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên cửa hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Total Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tổng Số Tiền (VNĐ)',
                    prefixIcon: Icon(Icons.payments_rounded),
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tổng tiền';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Field
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'Ngày Giao Dịch',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                    suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection Dropdown
                DropdownButtonFormField<ExpenseCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Phân Loại Danh Mục',
                    prefixIcon: Icon(Icons.category_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: ExpenseCategory.values.map((cat) {
                    return DropdownMenuItem<ExpenseCategory>(
                      value: cat,
                      child: Row(
                        children: [
                          Text(cat.iconEmoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(cat.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Expandable Raw OCR Text Block
                ExpansionTile(
                  title: const Text('Xem Văn Bản Thô (Raw OCR Text)'),
                  leading: const Icon(Icons.code_rounded),
                  initiallyExpanded: _showRawText,
                  onExpansionChanged: (exp) => setState(() => _showRawText = exp),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        widget.parsedReceipt.rawText.isEmpty
                            ? '(Không tìm thấy văn bản nào)'
                            : widget.parsedReceipt.rawText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Expense Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveExpense,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving ? 'Đang lưu vào CSDL...' : 'Lưu Giao Dịch Vào SQLite',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
