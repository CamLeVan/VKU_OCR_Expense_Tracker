import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/mlkit_ocr_service.dart';
import '../widgets/camera_crop_overlay.dart';
import 'ocr_review_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  final MlKitOcrService _ocrService = MlKitOcrService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Select back camera
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_isCameraInitialized) return;
    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      await _cameraController!.setFocusPoint(offset);
    } catch (_) {}
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing) return;

    try {
      String imagePath;

      if (_cameraController != null && _isCameraInitialized) {
        setState(() => _isProcessing = true);
        final XFile file = await _cameraController!.takePicture();
        imagePath = file.path;
      } else {
        // Fallback to gallery if camera unavailable
        final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (file == null) return;
        setState(() => _isProcessing = true);
        imagePath = file.path;
      }

      await _processImageAndNavigate(imagePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi quét hóa đơn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _isProcessing = true);
      await _processImageAndNavigate(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processImageAndNavigate(String imagePath) async {
    // Sub-100ms offline text extraction using Google ML Kit
    final parsedReceipt = await _ocrService.processImage(imagePath);

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OcrReviewScreen(
            imagePath: imagePath,
            parsedReceipt: parsedReceipt,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét Hóa Đơn (OCR)'),
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
              tooltip: 'Bật/Tắt Đèn Flash',
            ),
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            onPressed: _pickFromGallery,
            tooltip: 'Chọn ảnh từ thư viện',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Viewfinder Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTapFocus(details, constraints),
                  child: Stack(
                    children: [
                      Center(child: CameraPreview(_cameraController!)),
                      const CameraCropOverlay(),
                    ],
                  ),
                );
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Đang khởi tạo camera...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Chọn hóa đơn từ thư viện ảnh'),
                  ),
                ],
              ),
            ),

          // Processing Indicator Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Đang phân tích hóa đơn (On-Device AI)...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Google ML Kit OCR • Trí tuệ nhân tạo ngoại tuyến',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Shutter Button Bar
          if (!_isProcessing)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery shortcut
                  IconButton.filledTonal(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  // Main Shutter Button
                  GestureDetector(
                    onTap: _captureAndScan,
                    child: Container(
                      height: 76,
                      width: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF6750A4),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_rounded,
                          size: 38,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 56), // Spacer for symmetry
                ],
              ),
            ),
        ],
      ),
    );
  }
}
