import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project_3_ocr_expense_tracker/features/ocr_scanner/data/regex_heuristic_parser.dart';

void main() {
  group('RegexHeuristicParser Unit Tests', () {
    test('Extracts Vietnamese dot-separated currency correctly (150.000 đ)', () {
      const rawText = '''
CO.OPMART DA NANG
HD0012948
1. Bánh mì - 20.000
2. Sữa tươi - 130.000
TỔNG CỘNG: 150.000 đ
Ngày: 25/09/2026
Cảm ơn quý khách!
''';
      final lines = rawText.split('\n').map((l) => l.trim()).toList();

      final parsed = RegexHeuristicParser.parse(rawText: rawText, lines: lines);

      expect(parsed.merchant, equals('CO.OPMART DA NANG'));
      expect(parsed.totalAmount, equals(150000.0));
      expect(parsed.date, equals(DateTime(2026, 9, 25)));
    });

    test('Extracts comma-separated currency correctly (150,000 VND)', () {
      const rawText = '''
HIGHLANDS COFFEE
BILL #8841
TOTAL: 150,000 VND
DATE: 07/10/2026
''';
      final lines = rawText.split('\n').map((l) => l.trim()).toList();

      final parsed = RegexHeuristicParser.parse(rawText: rawText, lines: lines);

      expect(parsed.merchant, equals('HIGHLANDS COFFEE'));
      expect(parsed.totalAmount, equals(150000.0));
      expect(parsed.date, equals(DateTime(2026, 10, 7)));
    });

    test('Extracts large Vietnamese currency (1.500.000 VNĐ)', () {
      const rawText = '''
PHONG VU COMPUTER
Mặt hàng: Tai nghe Bluetooth
THANH TOÁN: 1.500.000 VNĐ
Ngày: 15-08-2026
''';
      final lines = rawText.split('\n').map((l) => l.trim()).toList();

      final parsed = RegexHeuristicParser.parse(rawText: rawText, lines: lines);

      expect(parsed.merchant, equals('PHONG VU COMPUTER'));
      expect(parsed.totalAmount, equals(1500000.0));
      expect(parsed.date, equals(DateTime(2026, 8, 15)));
    });

    test('Extracts "k" suffix amounts (50k)', () {
      const rawText = '''
TRÀ SỮA TOCOTOCO
1x Trà sữa nướng
CẦN THÀNH TOÁN: 50k
Ngày: 01/10/2026
''';
      final lines = rawText.split('\n').map((l) => l.trim()).toList();

      final parsed = RegexHeuristicParser.parse(rawText: rawText, lines: lines);

      expect(parsed.merchant, equals('TRÀ SỮA TOCOTOCO'));
      expect(parsed.totalAmount, equals(50000.0));
    });

    test('Handles noisy receipt header gracefully', () {
      const rawText = '''
HÓA ĐƠN BÁN HÀNG
BIÊN NHẬN THANH TOÁN
WINMART VKU
CẦN THÀNH TOÁN: 85.000đ
''';
      final lines = rawText.split('\n').map((l) => l.trim()).toList();

      final parsed = RegexHeuristicParser.parse(rawText: rawText, lines: lines);

      expect(parsed.merchant, equals('WINMART VKU'));
      expect(parsed.totalAmount, equals(85000.0));
    });
  });
}
