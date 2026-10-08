enum ExpenseCategory {
  food('Food', '🍽️', 0xFFFF5722),
  study('Study', '📚', 0xFF2196F3),
  travel('Travel', '🛵', 0xFF4CAF50),
  gear('Gear', '🎧', 0xFF9C27B0),
  entertainment('Entertainment', '🎬', 0xFFFF9800),
  other('Other', '🏷️', 0xFF607D8B);

  final String displayName;
  final String iconEmoji;
  final int colorHex;

  const ExpenseCategory(this.displayName, this.iconEmoji, this.colorHex);

  static ExpenseCategory fromString(String categoryStr) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == categoryStr.toLowerCase() ||
             e.displayName.toLowerCase() == categoryStr.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
