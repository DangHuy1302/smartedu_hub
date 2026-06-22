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

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      // 1. Xác định phòng dựa trên đặt chỗ của người dùng
      final booking = await _roomsService.getActiveBookingForUser(uid);
      if (booking != null) {
        setState(() {
          _currentRoomId = booking['roomId'];
        });
        
        if (_currentRoomId != null) {
          final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(_currentRoomId!).get();
          if (roomDoc.exists) {
            setState(() {
              _currentRoomName = roomDoc.data()?['name'];
            });
          }
        }
      }

      // 2. Lấy trạng thái Pomodoro hiện tại
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      
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
          } else {
            _state = PomodoroState.left;
          }
          
          if (_secondsRemaining > _initialMinutes * 60) {
             _initialMinutes = (_secondsRemaining / 60).ceil();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial state: $e');
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
           // Truyền roomId vào để lọc thành viên cùng phòng
           _pomodoroService.startPomodoro(uid: uid, roomId: _currentRoomId);
        }
      }

      setState(() {
        _isRunning = true;
        _state = PomodoroState.focusing;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
          
          if ((_initialMinutes * 60 - _secondsRemaining) % 30 == 0) {
            _syncProgress();
          }
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
      if (uid != null) {
        _pomodoroService.pausePomodoro(uid: uid, remainingSeconds: _secondsRemaining);
      }
    }
  }

  void _syncProgress() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _isRunning) {
      _pomodoroService.syncRemainingTime(uid: uid, remainingSeconds: _secondsRemaining);
    }
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
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: const Text('Chúc mừng bạn đã hoàn thành phiên học. Bạn muốn nhận điểm ngay chứ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            child: const Text('Nhận điểm & Kết thúc'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final booking = await _roomsService.getActiveBookingForUser(uid);
        if (booking != null && booking['id'] != null) {
          await _roomsService.cancelBooking(bookingId: booking['id']);
        }
      } catch (e) {
        debugPrint('Lỗi khi hoàn tác ghế: $e');
      }

      await _pomodoroService.endPomodoro(
        uid: uid,
        initialSeconds: _initialMinutes * 60,
        secondsRemaining: _secondsRemaining,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kết quả học tập và giải phóng chỗ ngồi!'))
        );
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
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _currentRoomName != null ? 'Phòng học: $_currentRoomName' : 'Phòng học Pomodoro',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
             if (_isRunning) {
               final leave = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Rời khỏi phòng?'),
                   content: const Text('Phiên học vẫn đang diễn ra. Bạn muốn lưu lại tiến trình chứ?'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                     TextButton(
                       onPressed: () {
                         _pomodoroService.leavePomodoro(
                           uid: FirebaseAuth.instance.currentUser!.uid,
                           remainingSeconds: _secondsRemaining
                         );
                         Navigator.pop(ctx, true);
                       },
                       child: const Text('Lưu & Rời đi'),
                     ),
                   ],
                 )
               );
               if (leave == true && mounted) Navigator.pop(context);
             } else {
               Navigator.pop(context);
             }
          },
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
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
          if (isDesktop) _buildMembersList(),
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
        if (_isRunning)
           const Padding(
             padding: EdgeInsets.only(top: 8),
             child: Text('Giữ màn hình luôn bật để tập trung tốt nhất', style: TextStyle(color: Colors.grey)),
           ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(
            value: _secondsRemaining / (_initialMinutes * 60),
            strokeWidth: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_state == PomodoroState.focusing ? const Color(0xFF1565C0) : Colors.orange),
          ),
        ),
        Text(
          _formatTime(_secondsRemaining),
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
        ),
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
            setState(() {
              _initialMinutes = v;
              _secondsRemaining = _initialMinutes * 60;
            });
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? Colors.orange : const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _isRunning ? null : () {
            setState(() {
              _secondsRemaining = _initialMinutes * 60;
              _state = PomodoroState.paused;
            });
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) _pomodoroService.cancelPomodoro(uid: uid);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Đặt lại'),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: _endSession,
          icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
          label: const Text('Kết thúc & Nhận điểm', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Bạn học cùng phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
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
                    
                    Color statusColor = status == 'focusing' ? Colors.green : (status == 'paused' ? Colors.orange : Colors.grey);
                    String statusLabel = status == 'focusing' ? 'Đang học' : (status == 'paused' ? 'Tạm nghỉ' : 'Vừa rời đi');

                    return _memberTile(name, statusLabel, statusColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(String name, String status, Color statusColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Text(name[0].toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(status, style: TextStyle(fontSize: 12, color: statusColor)),
        ],
      ),
    );
  }
}
