import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_document_service.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrDocumentService _service = OcrDocumentService();
  final TextEditingController _titleController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String _englishText = '';
  String _vietnameseText = '';
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _englishText = '';
      _vietnameseText = '';
      _selectedImage = null;
      _imageBytes = null;
    });

    final file = await _service.pickDocumentImage();
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _imageBytes = bytes;
      _titleController.text = file.name;
    });
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Vui lòng chọn ảnh trước khi quét.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _englishText = '';
      _vietnameseText = '';
    });

    try {
      final englishText = await _service.extractTextFromImage(_selectedImage!);
      final vietnameseText = await _service.translateToVietnamese(englishText);

      setState(() {
        _englishText = englishText;
        _vietnameseText = vietnameseText;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi xử lý OCR: ${e.toString()}';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveDocument() async {
    if (_englishText.isEmpty || _vietnameseText.isEmpty) {
      setState(
        () => _errorMessage =
            'Chưa có nội dung để lưu. Vui lòng quét tài liệu trước.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _service.saveDocument(
        title: _titleController.text.isEmpty
            ? 'Tài liệu OCR'
            : _titleController.text,
        englishText: _englishText,
        vietnameseText: _vietnameseText,
        imageFile: _selectedImage,
        audioUrl: null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu tài liệu vào kho Firestore thành công.'),
          ),
        );
        setState(() {
          _selectedImage = null;
          _imageBytes = null;
          _titleController.clear();
          _englishText = '';
          _vietnameseText = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi lưu tài liệu: ${e.toString()}';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Máy quét OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bước 1: Chọn ảnh đề thi hoặc tài liệu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
            const SizedBox(height: 12),
            if (_imageBytes != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _imageBytes!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImage,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Bắt đầu OCR & Dịch'),
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_englishText.isNotEmpty || _vietnameseText.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Bản gốc tiếng Anh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _englishText.isEmpty
                      ? 'Không tìm thấy văn bản.'
                      : _englishText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bản dịch tiếng Việt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _vietnameseText.isEmpty
                      ? 'Chưa có bản dịch.'
                      : _vietnameseText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveDocument,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu vào kho Firestore'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
