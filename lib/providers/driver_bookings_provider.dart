import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_booking_model.dart';

final driverBookingsProvider = FutureProvider<List<DriverBooking>>((ref) async {
  // 🔴 TEMP: mock backend response
  await Future.delayed(const Duration(seconds: 1));

  return [
    DriverBooking(
      bookingId: 'booking_1',
      passengerName: 'John D',
      address: '123 Main Street',
      area: 'Tembisa',
      notes: 'Blue gate',
    ),
  ];
});
