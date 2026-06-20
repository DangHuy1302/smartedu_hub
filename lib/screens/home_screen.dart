import 'package:flutter/material.dart';
import '../services/google_sign_in_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<User?> _authStream;
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  @override
  void initState() {
    super.initState();
    _authStream = _googleSignInService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Xám cực nhạt
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
        backgroundColor: const Color(0xFF1565C0), // Xanh biển đậm
        elevation: 0,
        actions: [
          if (isDesktop) ...[
            _navButton(context, 'Bản đồ Đặt chỗ', '/booking'),
            _navButton(context, 'Phòng Pomodoro', '/pomodoro'),
            _navButton(context, 'Máy quét OCR', '/ocr'),
            _navButton(context, 'Kho Audio', '/document'),
            StreamBuilder<User?>(
              stream: _authStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return _buildUserAvatar(context, snapshot.data!);
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/auth'),
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Đăng nhập', style: TextStyle(color: Colors.white)),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 2.2. Màn hình Trang chủ - Lời giới thiệu đầu trang (Hero Section)
            _buildHeroSection(isDesktop),
            
            // MAIN CONTENT (Grid View)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<User?>(
                    stream: _authStream,
                    builder: (context, snapshot) {
                      String name = snapshot.data?.displayName?.split(' ').last ?? 'Sinh Viên';
                      return Text(
                        'Xin chào, $name! 👋',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hôm nay bạn muốn tập trung vào việc gì?',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 48),
                  
                  // Khối Chức năng chính (Grid View)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 4 : (screenWidth > 600 ? 2 : 1),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.9,
                    children: [
                      _buildMenuCard(
                        context,
                        '📍 Bản đồ Đặt chỗ',
                        'Tìm kiếm và đặt không gian học tập ảo quanh trường.',
                        Icons.map_outlined,
                        Colors.blue,
                        '/booking',
                      ),
                      _buildMenuCard(
                        context,
                        '⏱️ Phòng học Pomodoro',
                        'Không gian đếm ngược tập trung, theo dõi trạng thái bạn bè.',
                        Icons.timer_outlined,
                        Colors.orange,
                        '/pomodoro',
                      ),
                      _buildMenuCard(
                        context,
                        '📷 Máy quét AI (OCR)',
                        'Chụp/Tải ảnh tài liệu để bóc tách chữ viết và dịch nghĩa.',
                        Icons.document_scanner_outlined,
                        Colors.purple,
                        '/ocr',
                      ),
                      _buildMenuCard(
                        context,
                        '📁 Kho Tài liệu & Audio',
                        'Lưu trữ các bài đọc cũ và bật trợ lý phát âm Audio Podcast.',
                        Icons.headphones_outlined,
                        Colors.green,
                        '/document',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Extra Footer section
            Container(
              padding: const EdgeInsets.all(40),
              color: Colors.white,
              width: double.infinity,
              child: const Column(
                children: [
                  Text(
                    'Hệ sinh thái SmartEdu Hub © 2024',
                    style: TextStyle(color: Colors.black38),
                  ),
                  Text(
                    'Nhóm: G5_Ca4 - Lớp 65HTTT (Đại học Thủy Lợi)',
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 100 : 60, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1565C0), Color(0xFFE3F2FD)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Học tập thông minh cùng\nSmartEdu Hub',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Text(
              'Hệ sinh thái đặt không gian học tập, số hóa tài liệu AI và luyện nghe TOEIC Podcast dành riêng cho sinh viên Cloud-Native.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800), // Cam nhấn (Màu 4)
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 8,
                  shadowColor: Colors.orange.withOpacity(0.4),
                ),
                child: const Text(
                  'Bắt đầu Đặt chỗ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text(
                  'Tìm hiểu về OCR AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, route),
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

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'logout') {
            await _googleSignInService.signOut();
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Text(user.displayName ?? 'Hồ sơ'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
        ),
      ),
    );
  }
}
