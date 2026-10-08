import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure local SQLite database initialized before runApp
  await DatabaseHelper.instance.database;
  runApp(const OcrExpenseTrackerApp());
}

class OcrExpenseTrackerApp extends StatelessWidget {
  const OcrExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker & Parser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainHomeScreen(),
    );
  }
}
