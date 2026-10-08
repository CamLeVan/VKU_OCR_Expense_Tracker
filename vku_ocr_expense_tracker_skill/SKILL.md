---
name: vku-ocr-expense-tracker
description: Offline receipt OCR, heuristic regex parsing, SQLite persistence, and CustomPainter analytics visualization in Flutter and Dart. Trigger whenever asked to build, update, or analyze an expense tracker app with OCR text recognition or custom canvas charts.
---

# VKU OCR Expense Tracker & Receipt Parser Skill

This skill outlines the architectural blueprint, OCR engine integration, heuristic regex patterns, and CustomPainter chart implementation for an offline personal finance app in Flutter 3.x and Dart 3.

## 🏛️ Architecture Overview

The app uses a Clean Feature-First Architecture:
- `core/database/database_helper.dart`: Production SQLite manager using `sqflite`.
- `features/ocr_scanner`: Google ML Kit Text Recognition wrapper (`MlKitOcrService`) & Heuristic Regex Engine (`RegexHeuristicParser`).
- `features/expenses`: SQLite DAO, models, list views, and CSV export.
- `features/analytics`: CustomPainter Canvas Donut Chart (`AnimatedPieChart`) & Bar Chart (`WeeklyBarChart`).

---

## 🧠 OCR & Regex Heuristics Engine Rules

### 1. Image OCR Processing (<100ms)
```dart
final inputImage = InputImage.fromFilePath(imagePath);
final recognizedText = await textRecognizer.processImage(inputImage);
```

### 2. Monetary Total Extraction Patterns
Match amounts formatted in Vietnamese & international currencies (e.g., `150.000 đ`, `150,000 VND`, `1.500.000 VNĐ`, `50k`):
```regex
r'(?:(?:VND|VNĐ|đ|Đ|\$)\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:VND|VNĐ|đ|Đ)?'
```
Prioritize lines containing keywords: `TỔNG CỘNG`, `THANH TOÁN`, `CẦN THÀNH TOÁN`, `TOTAL`, `NET AMOUNT`, `SUM`.

### 3. Date Extraction Patterns
Match `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`:
```regex
r'\b(0?[1-9]|[12][0-9]|3[01])[-/.](0?[1-9]|1[012])[-/.](19|20)\d\d\b'
```

### 4. Merchant Name Heuristics
Inspect top 5 lines of OCR text, filtering out generic headers (`HÓA ĐƠN`, `BIÊN NHẬN`, `RECEIPT`, `TEL`, `MST`).

---

## 🎨 CustomPainter Graphics Guidelines

- **Donut Chart:** Calculate `sweepAngle = (amount / totalAmount) * 2 * pi` and render using `canvas.drawArc()`.
- **Bar Chart:** Calculate `barHeight = (dailyAmount / maxAmount) * chartHeight * progress` and render using `canvas.drawRRect()`.
- **Animations:** Wrap canvas painters with `AnimationController` and `CurvedAnimation`. Do not use third-party chart libraries.

---

## 💾 Local SQLite Schema

```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  image_path TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX idx_expenses_date ON expenses (date);
```
