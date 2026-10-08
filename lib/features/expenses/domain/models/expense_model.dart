import 'expense_category.dart';

class ExpenseModel {
  final int? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? imagePath;
  final DateTime createdAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Map object to SQLite row
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create object from SQLite row map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.fromString(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ExpenseModel copyWith({
    int? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
