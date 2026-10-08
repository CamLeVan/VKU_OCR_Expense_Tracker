import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/models/parsed_receipt.dart';
import 'regex_heuristic_parser.dart';

class MlKitOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Process receipt image file using offline Google ML Kit Text Recognition
  /// Returns raw text blocks & parsed heuristic data (<100ms processing)
  Future<ParsedReceipt> processImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Receipt image file not found at path: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final rawText = recognizedText.text;
    final List<String> lines = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
        }
      }
    }

    // Pass extracted lines to Regex Heuristic Engine
    return RegexHeuristicParser.parse(
      rawText: rawText,
      lines: lines,
    );
  }

  /// Close resources when service is disposed
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
