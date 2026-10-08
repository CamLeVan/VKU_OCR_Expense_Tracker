import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final catColor = Color(expense.category.colorHex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  expense.category.iconEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            if (expense.imagePath != null && expense.imagePath!.isNotEmpty)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.document_scanner, color: Colors.white, size: 10),
              ),
          ],
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${dateFormat.format(expense.date)} • ${expense.category.displayName}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${currencyFormat.format(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.redAccent,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
