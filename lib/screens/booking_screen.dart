import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rooms_service.dart';
import '../services/zoho_form_service.dart';
import '../services/email_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final RoomsService _roomsService = RoomsService();
  late Stream<List<Map<String, dynamic>>> _roomsStream;
  final LatLng _initialCenter = const LatLng(21.007, 105.824);

  @override
  void initState() {
    super.initState();
    _roomsStream = _roomsService.streamRooms();
  }

  void _showBookingDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingBottomSheet(location: location, roomsService: _roomsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bản đồ Đặt chỗ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _roomsStream,
        builder: (context, roomsSnap) {
          if (roomsSnap.hasError) return const Center(child: Text('Lỗi tải dữ liệu phòng'));
          if (!roomsSnap.hasData) return const Center(child: CircularProgressIndicator());

          final rooms = roomsSnap.data!;
          final center = rooms.isNotEmpty
              ? LatLng(rooms.first['latitude'], rooms.first['longitude'])
              : _initialCenter;

          if (user == null) {
            return _buildMap(center, rooms, {});
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _roomsService.streamUserBookings(user.uid),
            builder: (context, bookingSnap) {
              final myBookings = bookingSnap.data ?? [];
              final bookedByMe = {for (var b in myBookings) b['roomId'] as String: b};

              return _buildMap(center, rooms, bookedByMe);
            },
          );
        },
      ),
    );
  }

  Widget _buildMap(LatLng center, List<Map<String, dynamic>> rooms, Map<String, Map<String, dynamic>> bookedByMe) {
    return FlutterMap(
      key: const ValueKey('booking_map_widget'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 17.0,
        minZoom: 13.0,
        maxZoom: 20.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.smartedu_hub',
        ),
        MarkerLayer(
          markers: rooms.map((loc) {
            final double lat = loc['latitude'];
            final double lng = loc['longitude'];
            final int seats = loc['availableSeats'];
            final String roomId = loc['id'];

            final myBooking = bookedByMe[roomId];
            final bool isBooked = myBooking != null;
            final markerColor = isBooked ? Colors.green : (seats > 0 ? Colors.red : Colors.grey);

            final locWithBooking = {...loc};
            if (isBooked) {
              locWithBooking['isBookedByMe'] = true;
              locWithBooking['bookingId'] = myBooking['id'];
              locWithBooking['bookedSeatCount'] = myBooking['seatCount'];
            }

            return Marker(
              width: 100,
              height: 100,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () => _showBookingDetails(locWithBooking),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 40, color: markerColor),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
                      ),
                      child: Text(
                        loc['name'] ?? '',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> location;
  final RoomsService roomsService;
  const _BookingBottomSheet({required this.location, required this.roomsService});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  int _seatCount = 1;

  @override
  void initState() {
    super.initState();
    final booked = widget.location['bookedSeatCount'] as int?;
    if (booked != null && booked > 0) {
      _seatCount = booked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBookedByMe = widget.location['isBookedByMe'] == true;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.location['name'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Còn ${widget.location['availableSeats']} / ${widget.location['totalSeats']} chỗ trống',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: widget.location['availableSeats'] > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          const Text('Số lượng ghế muốn đặt (Tối đa 5):', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              _counterButton(Icons.remove, () {
                if (_seatCount > 1) setState(() => _seatCount--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('$_seatCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              _counterButton(Icons.add, () {
                if (_seatCount < 5 && _seatCount < widget.location['seats']) {
                  setState(() => _seatCount++);
                }
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.location['seats'] > 0 ? () async {
                    await sendBookingEmail(
                      toEmail: 'levandan123321@gmail.com', 
                      bookingId: 'SEH-123456',
                      roomName: widget.location['name'] ?? 'Phong hoc',
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dat cho thanh cong! Email xac nhan da duoc gui.'),
                        backgroundColor: Colors.green,
                      )
                    );
                  } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800), // Cam nhấn (Màu 4)
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                _counterButton(Icons.add, () {
                  if (_seatCount < 5 && _seatCount < widget.location['availableSeats']) {
                    setState(() => _seatCount++);
                  }
                }),
                const Spacer(),
                ElevatedButton(
                  onPressed: widget.location['availableSeats'] > 0 ? () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
                      return;
                    }

                    try {
                      await widget.roomsService.bookRoom(
                        userId: user.uid,
                        roomId: widget.location['id'],
                        seatCount: _seatCount,
                        bookingDate: DateTime.now(),
                        startTime: 'Bây giờ',
                        endTime: 'Kết thúc học',
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Đặt chỗ thành công!'), backgroundColor: Colors.green)
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Giữ chỗ ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            const Text('Bạn đã đặt chỗ tại phòng này.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/pomodoro');
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text('Học tại phòng này'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await widget.roomsService.cancelBooking(bookingId: widget.location['bookingId']);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đặt chỗ.')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => openZohoForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đánh giá phòng học', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1565C0)),
      ),
    );
  }
}
