import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rooms_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final RoomsService _roomsService = RoomsService();

  // initial center (fallback)
  final LatLng _initialCenter = LatLng(21.007, 105.824);

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bản đồ Đặt chỗ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _roomsService.streamRooms(),
            builder: (context, snap) {
              final rooms = snap.data ?? [];
              final center = rooms.isNotEmpty
                  ? LatLng(rooms.first['latitude'] as double, rooms.first['longitude'] as double)
                  : _initialCenter;

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                // Not logged in: just show rooms
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 17.5,
                    minZoom: 13.0,
                    maxZoom: 20.0,
                    maxBounds: LatLngBounds(LatLng(21.003, 105.820), LatLng(21.012, 105.830)),
                    onTap: (tapPos, latlng) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.example.smartedu_hub'),
                    MarkerLayer(markers: rooms.map((loc) {
                      final lat = (loc['latitude'] ?? loc['lat']) as double;
                      final lng = (loc['longitude'] ?? loc['lng']) as double;
                      final seats = (loc['availableSeats'] ?? loc['seats'] ?? 0) as int;
                      return Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(lat, lng),
                        child: GestureDetector(
                          onTap: () => _showBookingDetails(loc),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 44, color: seats > 0 ? Colors.red : Colors.grey),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]), child: Text(loc['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      );
                    }).toList()),
                  ],
                );
              }

              // If logged in, include user's bookings to mark booked rooms green and allow undo
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _roomsService.streamUserBookings(user.uid),
                builder: (context, bookingSnap) {
                  final myBookings = bookingSnap.data ?? [];
                  // map roomId -> booking
                  final bookedByMe = <String, Map<String, dynamic>>{};
                  for (final b in myBookings) {
                    final roomId = b['roomId'] as String?;
                    if (roomId != null) bookedByMe[roomId] = b;
                  }

                  return FlutterMap(
                    options: MapOptions(
                      center: center,
                      zoom: 17.5,
                      minZoom: 13.0,
                      maxZoom: 20.0,
                      maxBounds: LatLngBounds(LatLng(21.003, 105.820), LatLng(21.012, 105.830)),
                      onTap: (tapPos, latlng) {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.example.smartedu_hub'),
                      MarkerLayer(markers: rooms.map((loc) {
                        final lat = (loc['latitude'] ?? loc['lat']) as double;
                        final lng = (loc['longitude'] ?? loc['lng']) as double;
                        final seats = (loc['availableSeats'] ?? loc['seats'] ?? 0) as int;
                        final roomId = loc['id'] ?? loc['roomId'];
                        final myBooking = roomId != null ? bookedByMe[roomId] : null;
                        final isBooked = myBooking != null;
                        final bookedSeatCount = isBooked ? (myBooking['seatCount'] ?? 0) as int : 0;

                        final markerColor = isBooked ? Colors.green : (seats > 0 ? Colors.red : Colors.grey);

                        final locWithBooking = {...loc};
                        if (isBooked) {
                          locWithBooking['isBookedByMe'] = true;
                          locWithBooking['bookingId'] = myBooking['bookingId'] ?? myBooking['id'];
                          locWithBooking['bookedSeatCount'] = bookedSeatCount;
                        }

                        return Marker(
                          width: 80,
                          height: 80,
                          point: LatLng(lat, lng),
                          child:  GestureDetector(
                            onTap: () => _showBookingDetails(locWithBooking),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 44, color: markerColor),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]), child: Text(loc['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        );
                      }).toList()),
                    ],
                  );
                },
              );
            },
          ),
          

        ],
      ),
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
                'Trạng thái: Còn ${widget.location['availableSeats'] ?? widget.location['seats']} / ${widget.location['totalSeats']} chỗ trống',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: (widget.location['availableSeats'] ?? widget.location['seats']) > 0 ? Colors.green : Colors.red,
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
                final maxAvailable = (widget.location['availableSeats'] ?? widget.location['seats']) as int;
                if (_seatCount < 5 && _seatCount < maxAvailable) {
                  setState(() => _seatCount++);
                }
              }),
              const Spacer(),
              if (widget.location['isBookedByMe'] == true) ...[
                ElevatedButton(
                  onPressed: () async {
                    final bookingId = widget.location['bookingId'];
                    if (bookingId == null) return;
                    try {
                      await widget.roomsService.cancelBooking(bookingId: bookingId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hoàn tác đặt chỗ.'), backgroundColor: Colors.orange));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hoàn tác thất bại: ${e.toString()}')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hoàn tác đặt chỗ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: (widget.location['availableSeats'] ?? widget.location['seats']) > 0 ? () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập trước khi đặt chỗ')));
                      return;
                    }

                    final seatCount = _seatCount;
                    final roomId = widget.location['id'] ?? widget.location['roomId'];
                    if (roomId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi phòng không xác định')));
                      return;
                    }

                    try {
                      await widget.roomsService.bookRoom(
                        userId: user.uid,
                        roomId: roomId,
                        seatCount: seatCount,
                        bookingDate: DateTime.now(),
                        startTime: 'Now',
                        endTime: 'Later',
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Đặt chỗ thành công! Email xác nhận đã được gửi.'), backgroundColor: Colors.green)
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt chỗ thất bại: ${e.toString()}')));
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800), // Cam nhấn (Màu 4)
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Giữ chỗ ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
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
