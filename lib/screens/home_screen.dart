import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tự động nhận diện chiều rộng màn hình để responsive
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800; // Màn hình PC

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              'SmartEdu Hub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5), // Xanh biển đậm
        elevation: 2,
        actions: [
          // THANH ĐIỀU HƯỚNG (NAVBAR) - Chỉ hiện trên màn hình máy tính rộng
          if (isDesktop) ...[
            _navButton(context, 'Bản đồ Đặt chỗ', '/booking'),
            _navButton(context, 'Phòng Pomodoro', '/pomodoro'),
            _navButton(context, 'Máy quét OCR', '/ocr'),
            _navButton(context, 'Kho Audio', '/docs'),
          ],
          const SizedBox(width: 24),
          // Avatar góc phải
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              'H',
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Container(
        // PHÔNG NỀN (BACKGROUND) - Đổ gradient từ Xanh nhạt sang Trắng cực kỳ hiện đại
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          // GIỚI HẠN KÍCH THƯỚC - Giữ nội dung ở giữa màn hình, rộng tối đa 1000px để không bị phình to
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào, Đăng Huy! 👋',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hôm nay bạn muốn tập trung vào việc gì?',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    // LƯỚI TỰ ĐỘNG CO GIÃN - Không dùng cố định 2 cột nữa
                    // Mỗi card sẽ có chiều rộng tối đa 250px, tự động rớt dòng nếu thu nhỏ màn hình
                    child: GridView.extent(
                      maxCrossAxisExtent: 250,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.0, // Tỷ lệ vuông cho các khối
                      children: [
                        _buildMenuCard(
                          context,
                          'Bản đồ Đặt chỗ',
                          Icons.map_outlined,
                          Colors.blue,
                          '/booking',
                        ),
                        _buildMenuCard(
                          context,
                          'Phòng Pomodoro',
                          Icons.timer_outlined,
                          Colors.orange,
                          '/pomodoro',
                        ),
                        _buildMenuCard(
                          context,
                          'Máy quét OCR',
                          Icons.document_scanner_outlined,
                          Colors.purple,
                          '/ocr',
                        ),
                        _buildMenuCard(
                          context,
                          'Kho Podcast',
                          Icons.headphones_outlined,
                          Colors.green,
                          '/docs',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Nút Chatbot lơ lửng
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Mở Zoho Chatbot')));
        },
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  // Widget: Các nút chữ trên Thanh Navbar
  Widget _navButton(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () {
          // Lệnh chuyển trang sau khi có file thật
          // Navigator.pushNamed(context, route);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đang trỏ tới $title')));
        },
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget: Khối Card giao diện ở giữa màn hình
  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () {
        // Lệnh chuyển trang
        // Navigator.pushNamed(context, route);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đang mở $title')));
      },
      hoverColor: color.withOpacity(
        0.05,
      ), // Hiệu ứng sáng lên khi lướt chuột qua
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
