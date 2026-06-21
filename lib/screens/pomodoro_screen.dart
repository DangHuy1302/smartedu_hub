import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartedu_hub/services/pomodoro_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Logic đếm ngược đơn giản (Chưa xử lý Firestore)
  int _secondsRemaining = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  int _initialMinutes = 25;
  final PomodoroService _pomodoroService = PomodoroService();

  void _startTimer() {
    if (_timer != null) return;
    setState(() => _isRunning = true);
    // mark user as active
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _pomodoroService.startPomodoro(uid: uid);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopTimer();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
    // mark user as inactive and save session
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _pomodoroService.endPomodoro(
        uid: uid,
        initialSeconds: _initialMinutes * 60,
        secondsRemaining: _secondsRemaining,
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Phòng học Pomodoro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: Row(
        children: [
          // TRÁI: Khu vực đồng hồ (Main content)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đang tập trung học tập',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 48),
                  
                  // 2.5. Đồng hồ đếm ngược trung tâm
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: CircularProgressIndicator(
                          value: _secondsRemaining / (25 * 60),
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                        ),
                      ),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _stopTimer : _startTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Tạm dừng' : 'Bắt đầu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRunning ? Colors.orange : const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _initialMinutes = 25;
                          _secondsRemaining = _initialMinutes * 60;
                          // cancel active flag
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) _pomodoroService.cancelPomodoro(uid: uid);
                        }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Đặt lại'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 80),
                  ElevatedButton(
                    onPressed: () async {
                      // End session and award points
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await _pomodoroService.endPomodoro(
                          uid: uid,
                          initialSeconds: _initialMinutes * 60,
                          secondsRemaining: _secondsRemaining,
                        );
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã rời phòng. Điểm đã được cộng.'))
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    ),
                    child: const Text('Kết thúc & Rời đi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          
          // PHẢI: Bảng Trạng thái Bạn học (Real-time Member List)
          // Gọi dữ liệu từ firestore để hiện thị danh sách bạn học và trang thái sử dụng realtime 
          if (isDesktop)
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Bạn học trực tuyến',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _pomodoroService.activeMembersStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final members = snapshot.data!;
                        if (members.isEmpty) return const Center(child: Text('Không có bạn học nào đang trực tuyến'));
                        return ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final m = members[i];
                            final name = (m['fullName'] ?? m['email'] ?? 'Người dùng') as String;
                            final status = (m['status'] ?? '') as String;
                            return _memberTile(name, status.isNotEmpty ? status : 'Đang tập trung', Colors.green);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _memberTile(String name, String status, Color statusColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(name[0]),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(status, style: TextStyle(fontSize: 12, color: statusColor)),
        ],
      ),
    );
  }
}
