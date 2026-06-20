import 'package:flutter/material.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  // Mock data cho danh sách tài liệu
  final List<Map<String, String>> _documents = [
    {
      'title': 'AI in Education - Overview',
      'date': '20/10/2023',
      'content': 'Artificial Intelligence is transforming how we learn...',
      'translation': 'Trí tuệ nhân tạo đang thay đổi cách chúng ta học tập...'
    },
    {
      'title': 'TOEIC Reading Practice Part 5',
      'date': '18/10/2023',
      'content': 'The company announced that it will implement new policies...',
      'translation': 'Công ty thông báo rằng họ sẽ triển khai các chính sách mới...'
    },
    {
      'title': 'Cloud Computing Basics',
      'date': '15/10/2023',
      'content': 'Cloud computing is the on-demand availability of computer system resources...',
      'translation': 'Điện toán đám mây là khả năng cung cấp theo yêu cầu các tài nguyên hệ thống máy tính...'
    },
  ];

  Map<String, String>? _selectedDoc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kho Tài liệu & Audio', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          if (_selectedDoc != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedDoc = null),
            )
        ],
      ),
      body: Stack(
        children: [
          _selectedDoc == null ? _buildListView() : _buildDetailView(),
          
          // 2.6. Trình điều khiển âm thanh (Audio Player Panel) - Cố định ở cạnh dưới
          if (_selectedDoc != null) _buildAudioPlayer(),
        ],
      ),
    );
  }

  // 2.6. Danh sách tài liệu (List View)
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.description_outlined, color: Color(0xFF1565C0)),
            ),
            title: Text(doc['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Ngày lưu: ${doc['date']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedDoc = doc),
          ),
        );
      },
    );
  }

  // 2.6. Màn hình xem chi tiết tài liệu (Clean UI)
  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120), // Padding bottom để không bị che bởi player
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedDoc!['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          const SizedBox(height: 24),
          
          // Layout chia đôi hoặc dọc tùy màn hình
          LayoutBuilder(builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 800;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _contentBox('TIẾNG ANH (GỐC)', _selectedDoc!['content']!, Colors.blue[50]!),
                ),
                if (isWide) const SizedBox(width: 24) else const SizedBox(height: 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _contentBox('TIẾNG VIỆT (DỊCH)', _selectedDoc!['translation']!, Colors.green[50]!),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _contentBox(String label, String text, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }

  // 2.6. Trình điều khiển âm thanh (Audio Player Panel)
  Widget _buildAudioPlayer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Nút Phát Audio (Podcast)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔊 Đang gọi Google Text-to-Speech API...'))
                    );
                  },
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text('Phát Podcast AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.skip_previous, color: Color(0xFF1565C0)),
                const SizedBox(width: 16),
                const CircleAvatar(
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.skip_next, color: Color(0xFF1565C0)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('0:00', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: 0,
                    onChanged: (v) {},
                    activeColor: const Color(0xFF1565C0),
                  ),
                ),
                const Text('3:45', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
