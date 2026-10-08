import '../domain/models/parsed_receipt.dart';

class RegexHeuristicParser {
  /// Heuristic keywords indicating receipt total amount
  static final List<String> _totalKeywords = [
    'tổng cộng',
    'tong cong',
    'tổng tiền',
    'tong tien',
    'thanh toán',
    'thanh toan',
    'thành toán',
    'cần thanh toán',
    'can thanh toan',
    'cần thành toán',
    'tổng thanh toán',
    'tổng thành toán',
    'total',
    'grand total',
    'net amount',
    'sum',
    'tiền mặt',
    'tien mat',
    'cộng tiền',
  ];

  /// Keywords indicating lines to skip for Merchant Name heuristic
  static final List<String> _merchantSkipKeywords = [
    'hóa đơn',
    'hoa don',
    'biên nhận',
    'bien nhan',
    'receipt',
    'invoice',
    'phiếu thanh toán',
    'phieu thanh toan',
    'cửa hàng',
    'cua hang',
    'welcome',
    'kính chào',
    'kinh chao',
    'cảm ơn',
    'cam on',
    'tel',
    'phone',
    'mst',
    'mã số thuế',
    'đc',
    'địa chỉ',
    'address',
    'stt',
    'ngày',
    'date',
  ];

  /// Parse raw text lines into structured ParsedReceipt data
  static ParsedReceipt parse({
    required String rawText,
    required List<String> lines,
  }) {
    final merchant = _extractMerchant(lines);
    final totalAmount = _extractTotalAmount(lines, rawText);
    final date = _extractDate(lines, rawText);

    return ParsedReceipt(
      merchant: merchant,
      totalAmount: totalAmount,
      date: date,
      rawText: rawText,
      rawLines: lines,
    );
  }

  // --- MERCHANT EXTRACTION ---
  static String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    // Search top 5 lines for store/merchant name
    final maxCheck = lines.length < 5 ? lines.length : 5;
    for (int i = 0; i < maxCheck; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (line.isEmpty || line.length < 2) continue;

      // Skip generic receipt headers or tax/phone numbers
      bool shouldSkip = _merchantSkipKeywords.any((kw) => lower.contains(kw));
      if (shouldSkip) continue;

      // Skip lines that are purely numbers or currency symbols
      if (RegExp(r'^\d+[\d\s.,/-]*$').hasMatch(line)) continue;

      // Found potential merchant name (e.g. "CO.OPMART", "HIGHLANDS COFFEE", "WINMART")
      return line;
    }

    return lines.firstWhere(
      (l) => l.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(l.trim()),
      orElse: () => 'Cửa hàng không xác định',
    );
  }

  // --- TOTAL AMOUNT EXTRACTION ---
  static double? _extractTotalAmount(List<String> lines, String rawText) {
    double? bestAmount;
    int highestScore = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Check if line contains total keyword
      for (final kw in _totalKeywords) {
        if (lower.contains(kw)) {
          int score = 100;
          // Lines near bottom have higher score heuristic
          score += (i * 2);

          // Extract amounts from current line
          double? amount = _extractAmountFromText(line);

          // If no amount on current line, check next line
          if (amount == null && i + 1 < lines.length) {
            amount = _extractAmountFromText(lines[i + 1]);
          }

          if (amount != null && amount > 0) {
            if (score > highestScore) {
              highestScore = score;
              bestAmount = amount;
            }
          }
        }
      }
    }

    // Fallback: search overall text for highest reasonable monetary figure
    if (bestAmount == null) {
      final amounts = _findAllAmountsInText(rawText);
      if (amounts.isNotEmpty) {
        // Filter out improbable amounts (e.g. phone numbers or years)
        final validAmounts = amounts.where((a) => a >= 1000 && a <= 100000000).toList();
        if (validAmounts.isNotEmpty) {
          validAmounts.sort();
          bestAmount = validAmounts.last; // Highest amount on receipt
        }
      }
    }

    return bestAmount;
  }

  static double? _extractAmountFromText(String text) {
    // Check "50k" or "150K" format first
    final kRegex = RegExp(r'(\d+)\s*[kK]\b');
    final kMatch = kRegex.firstMatch(text);
    if (kMatch != null) {
      final numStr = kMatch.group(1);
      if (numStr != null) {
        return (double.tryParse(numStr) ?? 0) * 1000;
      }
    }

    final regex = RegExp(
      r'(?:(?:VND|VNĐ|đ|Đ|\$)\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:VND|VNĐ|đ|Đ)?',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    for (final match in matches) {
      final matchedStr = match.group(1);
      if (matchedStr != null) {
        final parsed = _parseAmountString(matchedStr, text);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    return null;
  }

  static List<double> _findAllAmountsInText(String text) {
    final List<double> results = [];
    final regex = RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b|\b\d{4,8}\b');
    final matches = regex.allMatches(text);
    for (final m in matches) {
      final str = m.group(0);
      if (str != null) {
        final val = _parseAmountString(str, text);
        if (val != null) results.add(val);
      }
    }
    return results;
  }

  static double? _parseAmountString(String rawNumberStr, String fullLineContext) {
    String cleanStr = rawNumberStr.replaceAll(' ', '');

    // Handle "150.000" (Vietnamese dot thousands separator)
    if (cleanStr.contains('.') && !cleanStr.contains(',')) {
      final parts = cleanStr.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        // e.g. 150.000 -> 150000
        cleanStr = cleanStr.replaceAll('.', '');
      } else if (parts.length == 2 && parts.last.length == 2) {
        // e.g. 150.50 -> standard decimal
      } else {
        cleanStr = cleanStr.replaceAll('.', '');
      }
    }
    // Handle "150,000" (Comma thousands separator)
    else if (cleanStr.contains(',') && !cleanStr.contains('.')) {
      final parts = cleanStr.split(',');
      if (parts.length > 1 && parts.last.length == 3) {
        cleanStr = cleanStr.replaceAll(',', '');
      } else {
        cleanStr = cleanStr.replaceAll(',', '.');
      }
    }
    // Handle "150,000.00" or "150.000,00"
    else if (cleanStr.contains('.') && cleanStr.contains(',')) {
      if (cleanStr.indexOf('.') < cleanStr.indexOf(',')) {
        // 150.000,00
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 150,000.00
        cleanStr = cleanStr.replaceAll(',', '');
      }
    }

    final double? val = double.tryParse(cleanStr);
    if (val != null) {
      // Check if context contains 'k' or 'K' right after number
      if (RegExp(rawNumberStr + r'\s*[kK]\b').hasMatch(fullLineContext)) {
        return val * 1000;
      }
      return val;
    }
    return null;
  }

  // --- DATE EXTRACTION ---
  static DateTime? _extractDate(List<String> lines, String rawText) {
    // Standard formats: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD, DD/MM/YY
    final List<RegExp> dateRegexes = [
      // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[-/.](0?[1-9]|1[012])[-/.](19|20)\d\d\b'),
      // YYYY-MM-DD or YYYY/MM/DD
      RegExp(r'\b(19|20)\d\d[-/.](0?[1-9]|1[012])[-/.](0?[1-9]|[12][0-9]|3[01])\b'),
      // DD/MM/YY
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[-/.](0?[1-9]|1[012])[-/.](2[0-9])\b'),
    ];

    for (final regex in dateRegexes) {
      final match = regex.firstMatch(rawText);
      if (match != null) {
        final dateStr = match.group(0);
        if (dateStr != null) {
          final parsed = _parseDateString(dateStr);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  static DateTime? _parseDateString(String dateStr) {
    try {
      final clean = dateStr.replaceAll('-', '/').replaceAll('.', '/');
      final parts = clean.split('/');
      if (parts.length == 3) {
        int year, month, day;
        if (parts[0].length == 4) {
          // YYYY/MM/DD
          year = int.parse(parts[0]);
          month = int.parse(parts[1]);
          day = int.parse(parts[2]);
        } else {
          // DD/MM/YYYY or DD/MM/YY
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
          year = int.parse(parts[2]);
          if (year < 100) year += 2000;
        }

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      // Invalid date parse
    }
    return null;
  }
}
