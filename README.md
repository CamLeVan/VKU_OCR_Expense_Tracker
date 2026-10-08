# 🧾 Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![MLKit](https://img.shields.io/badge/Google_ML_Kit-Text_Recognition-4285F4?logo=google)](https://developers.google.com/ml-kit)
[![SQLite](https://img.shields.io/badge/Database-sqflite-003B57?logo=sqlite)](https://pub.dev/packages/sqflite)

An offline personal finance management application with **On-Device AI Receipt OCR**, regex heuristic extraction, persistent SQLite storage, and library-free **CustomPainter animated charts**.

---

## 🏛️ Modular Architecture

This project follows a **Clean Feature-First Architecture**:

```text
lib/
├── core/
│   ├── constants/        # App constants, colors, regex rules
│   ├── database/         # SQLite DatabaseHelper (sqflite)
│   ├── theme/            # Material 3 light & dark themes
│   └── utils/            # Currency & Date formatters
└── features/
    ├── expenses/         # Transaction CRUD & Domain Models
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── ocr_scanner/      # ML Kit OCR & Regex Heuristic Engine
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── analytics/        # CustomPainter Donut & Bar Charts
        └── presentation/
```

---

## 🛠️ Prerequisites & Installation

### Requirements
- Flutter SDK: `>=3.10.0`
- Dart SDK: `>=3.0.0`
- Android Studio / VS Code with Flutter extension
- Physical Android/iOS Device or Emulator

### Setup Steps
```bash
# Clone repository
git clone https://github.com/CamLeVan/VKU_OCR_Expense_Tracker.git
cd MiniProject3

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## 📋 Features & Roadmap

- [x] **Phase 1:** Feature-First Modular Architecture & `sqflite` Database Helper.
- [ ] **Phase 2:** On-Device Google ML Kit Text Recognition (<100ms) & Regex Parser.
- [ ] **Phase 3:** Live Camera Capture & Framing Overlay.
- [ ] **Phase 4:** Interactive OCR Review & Expense Persistence with Thumbnail Cache.
- [ ] **Phase 5:** Library-free `CustomPainter` Animated Pie & Bar Charts.
