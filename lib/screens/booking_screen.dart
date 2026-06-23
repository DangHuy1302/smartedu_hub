import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/zoho_form_service.dart';
import '../services/email_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Mock data for locations
  final List<Map<String, dynamic>> _locations = [
    {'name': 'Thư viện Tầng 1 - Nhà T35', 'seats': 12, 'total': 50, 'lat': 21.007, 'lng': 105.824},
    {'name': 'The Coffee House (Chùa Bộc)', 'seats': 5, 'total': 20, 'lat': 21.008, 'lng': 105.826},
    {'name': 'Không gian tự học - Nhà C1', 'seats': 0, 'total': 15, 'lat': 21.006, 'lng': 105.823},
  ];

  void _showBookingDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingBottomSheet(location: location),
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
          FlutterMap(
            options: MapOptions(
              center: LatLng(_locations.first['lat'], _locations.first['lng']),
              zoom: 17.5,
              minZoom: 13.0,
              maxZoom: 20.0,
              // Approximate bounds for Đại học Thủy Lợi campus. Adjust if you have more accurate coords.
              maxBounds: LatLngBounds(
                LatLng(21.003, 105.820), // southwest
                LatLng(21.012, 105.830), // northeast
              ),
              onTap: (tapPos, latlng) {
                // Close any open bottom sheet when tapping the map
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.smartedu_hub',
              ),
              MarkerLayer(
                markers: _locations.map((loc) {
                  final lat = loc['lat'] as double;
                  final lng = loc['lng'] as double;
                  return Marker(
                    width: 80,
                    height: 80,
                    point: LatLng(lat, lng),
                    builder: (ctx) => GestureDetector(
                      onTap: () => _showBookingDetails(loc),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 44,
                            color: loc['seats'] > 0 ? Colors.red : Colors.grey,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                            ),
                            child: Text(loc['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          

        ],
      ),
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> location;
  const _BookingBottomSheet({required this.location});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  int _seatCount = 1;

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
                'Trạng thái: Còn ${widget.location['seats']} / ${widget.location['total']} chỗ trống',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: widget.location['seats'] > 0 ? Colors.green : Colors.red,
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
                child: const Text('Giữ chỗ ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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
