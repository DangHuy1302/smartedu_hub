import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendBookingEmail({
  required String toEmail,
  required String bookingId,
  required String roomName,
}) async {
  await FirebaseFirestore.instance.collection('mail').add({
    'to': toEmail,
    'message': {
      'subject': 'Xác nhận đặt phòng - $bookingId',
      'html': 'Mã đặt phòng: $bookingId <br> Phòng: $roomName',
    },
  });
}