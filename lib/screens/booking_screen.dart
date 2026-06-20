import 'package:flutter/material.dart';

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
          // 2.3. Bản đồ Tràn viền (Placeholder for Google Maps)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE3F2FD),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_rounded, size: 100, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Google Maps SDK - Khu vực ĐH Thủy Lợi',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  // Mock Markers
                  Wrap(
                    spacing: 20,
                    children: _locations.map((loc) => InkWell(
                      onTap: () => _showBookingDetails(loc),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on, 
                            size: 48, 
                            color: loc['seats'] > 0 ? Colors.red : Colors.grey
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
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Chatbot (Global Rule)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
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
                onPressed: widget.location['seats'] > 0 ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Đặt chỗ thành công! Email xác nhận đã được gửi.'),
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
