import 'package:flutter/material.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  bool _isProcessing = false;
  String _ocrResult = "";
  String _translatedResult = "";
  bool _showTranslation = false;

  void _simulateOcr() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        _ocrResult = "SmartEdu Hub is a platform for students of Thuy Loi University. It provides tools for study space booking and document digitalization using AI technologies.";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Máy quét AI (OCR Hub)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2.4. Phần Trái/Trên (Upload & Preview)
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: _ocrResult.isEmpty && !_isProcessing
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text('Kéo thả hoặc bấm để tải ảnh tài liệu lên', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _simulateOcr,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: const Text('Chọn ảnh từ máy'),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=1000&auto=format&fit=crop',
                                      fit: BoxFit.cover,
                                    ),
                                    if (_isProcessing)
                                      Container(
                                        color: Colors.black45,
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      if (_ocrResult.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _simulateOcr,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Quét lại OCR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (isDesktop) const SizedBox(width: 32) else const SizedBox(height: 32),

                // 2.4. Phần Phải/Dưới (AI Text Result)
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                                const SizedBox(width: 8),
                                const Text('Kết quả nhận diện AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (_ocrResult.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.copy_all, size: 20),
                                    onPressed: () {},
                                    tooltip: 'Sao chép',
                                  ),
                              ],
                            ),
                            const Divider(height: 32),
                            if (_ocrResult.isEmpty && !_isProcessing)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60.0),
                                  child: Text('Chưa có dữ liệu. Vui lòng tải ảnh lên.', style: TextStyle(color: Colors.black38)),
                                ),
                              )
                            else ...[
                              Text(
                                _ocrResult,
                                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              ),
                              if (_showTranslation) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('BẢN DỊCH TIẾNG VIỆT:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'SmartEdu Hub là một nền tảng dành cho sinh viên Đại học Thủy Lợi. Nó cung cấp các công cụ để đặt chỗ học tập và số hóa tài liệu bằng công nghệ AI.',
                                        style: TextStyle(fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Thanh công cụ xử lý
                      if (_ocrResult.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _showTranslation = !_showTranslation),
                                icon: const Icon(Icons.translate),
                                label: Text(_showTranslation ? 'Ẩn bản dịch' : '🌐 Dịch tự động'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 Đã lưu vào Kho tài liệu cá nhân!')));
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('💾 Lưu vào Kho'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
