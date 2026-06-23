import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartedu_hub/services/pomodoro_service.dart';
import 'package:smartedu_hub/services/rooms_service.dart';

enum PomodoroState { focusing, paused, left }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _secondsRemaining = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  int _initialMinutes = 25;
  PomodoroState _state = PomodoroState.paused;
  final PomodoroService _pomodoroService = PomodoroService();
  final RoomsService _roomsService = RoomsService();
  
  String? _currentRoomId;
  String? _currentRoomName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final booking = await _roomsService.getActiveBookingForUser(uid);
      if (booking != null) {
        _currentRoomId = booking['roomId'];
        if (_currentRoomId != null) {
          final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(_currentRoomId!).get();
          if (roomDoc.exists) {
            _currentRoomName = roomDoc.data()?['name'];
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã kết nối vào không gian: $_currentRoomName'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chế độ tự học Offline (Bạn chưa đặt phòng)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final status = data['status'] as String?;
        final remaining = data['pomodoroRemainingSeconds'] as int?;
        
        if (status != null && remaining != null && remaining > 0) {
          setState(() {
            _secondsRemaining = remaining;
            if (status == 'focusing') {
              _state = PomodoroState.focusing;
              _toggleTimer(true); 
            } else if (status == 'paused') {
              _state = PomodoroState.paused;
            }
            if (_secondsRemaining > _initialMinutes * 60) {
               _initialMinutes = (_secondsRemaining / 60).ceil();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading initial state: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTimer(bool start) {
    if (start) {
      if (_timer != null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        if (_state == PomodoroState.focusing) {
           _pomodoroService.resumePomodoro(uid: uid);
        } else {
           _pomodoroService.startPomodoro(uid: uid, roomId: _currentRoomId);
        }
      }
      setState(() {
        _isRunning = true;
        _state = PomodoroState.focusing;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
          if ((_initialMinutes * 60 - _secondsRemaining) % 30 == 0) _syncProgress();
        } else {
          _handleTimerComplete();
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
      setState(() {
        _isRunning = false;
        _state = PomodoroState.paused;
      });
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _pomodoroService.pausePomodoro(uid: uid, remainingSeconds: _secondsRemaining);
    }
  }

  void _syncProgress() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _isRunning) _pomodoroService.syncRemainingTime(uid: uid, remainingSeconds: _secondsRemaining);
  }

  void _handleTimerComplete() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _state = PomodoroState.paused;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tuyệt vời!'),
        content: const Text('Bạn đã hoàn thành phiên học xuất sắc. Nhận điểm ngay thôi!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Nhận điểm & Kết thúc'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Xác định chế độ: Nếu có _currentRoomId thì là phiên Online
      final bool isOnlineMode = _currentRoomId != null;
      bool bookingWasReleased = false;

      // 2. Chỉ thực hiện giải phóng nếu là Online mode
      if (isOnlineMode) {
        final booking = await _roomsService.getActiveBookingForUser(uid);
        if (booking != null) {
          await _roomsService.cancelBooking(bookingId: booking['id']);
          bookingWasReleased = true;
        }
      }

      // 3. Kết thúc Pomodoro và tính điểm
      final pointsEarned = await _pomodoroService.endPomodoro(
        uid: uid,
        initialSeconds: _initialMinutes * 60,
        secondsRemaining: _secondsRemaining,
      );
      
      if (mounted) {
        Navigator.pop(context); // Trở về Trang chủ
        
        // 4. Xây dựng thông báo thông minh theo chế độ
        String msg = 'Chúc mừng! Bạn đã nhận được $pointsEarned điểm tích lũy.';
        if (isOnlineMode && bookingWasReleased) {
          msg += ' Hệ thống đã giải phóng chỗ ngồi cho bạn tại $_currentRoomName.';
        } else {
          msg += ' Tiếp tục phát huy tinh thần tự học nhé!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.yellow, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
            backgroundColor: const Color(0xFF1565C0),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
      }
    } catch (e) {
      debugPrint('Lỗi kết thúc phiên: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không thể lưu kết quả học tập.')));
        setState(() => _isLoading = false);
      }
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    double screenWidth = MediaQuery.of(context).size.width;
    bool isOnline = _currentRoomId != null;
    bool showSidebar = screenWidth > 900 && isOnline;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isOnline ? 'Phòng học: $_currentRoomName' : 'Chế độ tự học Offline', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusHeader(),
                    const SizedBox(height: 48),
                    _buildTimerDisplay(),
                    const SizedBox(height: 24),
                    _buildDurationSelector(),
                    const SizedBox(height: 48),
                    _buildActionButtons(),
                    const SizedBox(height: 60),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
          if (showSidebar) _buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    String statusText = _state == PomodoroState.focusing ? 'Đang tập trung học tập' : 'Đã tạm dừng';
    Color statusColor = _state == PomodoroState.focusing ? Colors.green : Colors.orange;
    return Column(
      children: [
        Text(statusText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
        if (_isRunning) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Giữ màn hình luôn bật để tập trung tốt nhất', style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280, height: 280,
          child: CircularProgressIndicator(
            value: _secondsRemaining / (_initialMinutes * 60),
            strokeWidth: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_state == PomodoroState.focusing ? const Color(0xFF1565C0) : Colors.orange),
          ),
        ),
        Text(_formatTime(_secondsRemaining), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Thời lượng: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _initialMinutes,
          items: [1, 10, 20, 25, 30, 45, 60].map((m) => DropdownMenuItem(value: m, child: Text('$m phút'))).toList(),
          onChanged: _isRunning ? null : (v) {
            if (v == null) return;
            setState(() { _initialMinutes = v; _secondsRemaining = _initialMinutes * 60; });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _toggleTimer(!_isRunning),
          icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(_isRunning ? 'Tạm dừng' : 'Bắt đầu'),
          style: ElevatedButton.styleFrom(backgroundColor: _isRunning ? Colors.orange : const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _isRunning ? null : () {
            setState(() { _secondsRemaining = _initialMinutes * 60; _state = PomodoroState.paused; });
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) _pomodoroService.cancelPomodoro(uid: uid);
          },
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Đặt lại'),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextButton.icon(onPressed: _endSession, icon: const Icon(Icons.stop_circle, color: Colors.redAccent), label: const Text('Kết thúc & Nhận điểm', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildMembersList() {
    return Container(
      width: 300,
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey[200]!))),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(24), child: Text('Bạn học cùng phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _pomodoroService.activeMembersStream(_currentRoomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final members = snapshot.data!;
                if (members.isEmpty) return const Center(child: Text('Không có ai khác trong phòng', style: TextStyle(color: Colors.grey)));
                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final m = members[i];
                    final String name = m['fullName'] ?? m['email']?.split('@')[0] ?? 'Bạn học';
                    final String status = m['status'] ?? 'focusing';
                    final int points = (m['studyPoints'] ?? 0) as int;
                    Color statusColor = status == 'focusing' ? Colors.green : (status == 'paused' ? Colors.orange : Colors.grey);
                    return _memberTile(name, status == 'focusing' ? 'Đang học' : 'Tạm nghỉ', statusColor, points);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(String name, String status, Color statusColor, int points) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.1), child: Text(name[0].toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text('$points pts', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))),
      ]),
      subtitle: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(status, style: TextStyle(fontSize: 12, color: statusColor))]),
    );
  }
}
