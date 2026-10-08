class ParsedReceipt {
  final String? merchant;
  final double? totalAmount;
  final DateTime? date;
  final String rawText;
  final List<String> rawLines;

  ParsedReceipt({
    this.merchant,
    this.totalAmount,
    this.date,
    required this.rawText,
    required this.rawLines,
  });

  @override
  String toString() {
    return 'ParsedReceipt(merchant: $merchant, totalAmount: $totalAmount, date: $date, lines: ${rawLines.length})';
  }
}
