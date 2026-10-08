import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/models/expense_model.dart';

class ExpenseExportService {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Export all expenses stored in SQLite to a CSV file formatted for Excel
  Future<File> exportExpensesToCsv() async {
    final rows = await DatabaseHelper.instance.queryAllExpenses();
    final expenses = rows.map((r) => ExpenseModel.fromMap(r)).toList();

    final StringBuffer csvBuffer = StringBuffer();

    // CSV Header with BOM for UTF-8 Excel support
    csvBuffer.writeln('\uFEFFID,Tên Cửa Hàng / Nội Dung,Số Tiền (VNĐ),Danh Mục,Ngày Giao Dịch,Đường Dẫn Ảnh,Ngày Tạo');

    for (final exp in expenses) {
      final id = exp.id ?? '';
      final title = _escapeCsvField(exp.title);
      final amount = exp.amount.toStringAsFixed(0);
      final category = _escapeCsvField(exp.category.displayName);
      final date = _dateFormat.format(exp.date);
      final imagePath = _escapeCsvField(exp.imagePath ?? '');
      final createdAt = _dateFormat.format(exp.createdAt);

      csvBuffer.writeln('$id,$title,$amount,$category,$date,$imagePath,$createdAt');
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'danh_sach_chi_tieu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final filePath = p.join(directory.path, fileName);

    final file = File(filePath);
    await file.writeAsString(csvBuffer.toString(), flush: true);

    return file;
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}
