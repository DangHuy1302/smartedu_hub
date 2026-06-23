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
    });

    try {
      final extracted = await _service.extractTextFromImage(_selectedImage!);
      setState(() => _englishText = extracted);

      if (extracted.isNotEmpty) {
        final translated = await _service.translateToVietnamese(extracted);
        setState(() => _vietnameseText = translated);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi xử lý OCR: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveDocument() async {
    if (_englishText.isEmpty) {
      setState(() => _errorMessage = 'Chưa có nội dung để lưu.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _service.saveDocument(
        title: _titleController.text.trim().isEmpty
            ? 'Tài liệu không tên'
            : _titleController.text,
        extractedText: _englishText,
        translatedText: _vietnameseText,
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu tài liệu thành công.'),
            duration: Duration(milliseconds: 1500),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      final msg = 'Lỗi lưu tài liệu: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      // keep console log for debugging
      // ignore: avoid_print
      print(msg);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Máy quét OCR AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePickerArea(),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề tài liệu',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing || _selectedImage == null
                  ? null
                  : _processImage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isProcessing ? 'Đang xử lý...' : 'Bắt đầu Quét & Dịch',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_englishText.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildResultCard(
                'Bản gốc (OCR)',
                _englishText,
                Colors.blue.shade50,
              ),
              const SizedBox(height: 16),
              if (_vietnameseText.isNotEmpty)
                _buildResultCard(
                  'Bản dịch (Vietnamese)',
                  _vietnameseText,
                  Colors.orange.shade50,
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveDocument,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('LƯU VÀO KHO TÀI LIỆU'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return InkWell(
      onTap: _isProcessing ? null : _pickImage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Color(0xFF1565C0),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nhấn để chọn ảnh tài liệu',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard(String label, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
