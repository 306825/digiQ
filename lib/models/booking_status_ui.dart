// import 'package:digiQ/models/booking_model.dart';
// import 'package:flutter/material.dart';

// extension BookingStatusUI on BookingStatus {
//   String get label {
//     switch (this) {
//       case BookingStatus.pending:
//         return 'PENDING';
//       case BookingStatus.approved:
//         return 'APPROVED';
//       case BookingStatus.rejected:
//         return 'REJECTED';
//     }
//   }

//   String get description {
//     switch (this) {
//       case BookingStatus.pending:
//         return 'Waiting for driver response';
//       case BookingStatus.approved:
//         return 'Driver approved your booking';
//       case BookingStatus.rejected:
//         return 'Driver rejected your booking';
//     }
//   }

//   Color get color {
//     switch (this) {
//       case BookingStatus.pending:
//         return Colors.orange;
//       case BookingStatus.approved:
//         return Colors.green;
//       case BookingStatus.rejected:
//         return Colors.red;
//     }
//   }
// }

import 'package:digiQ/models/booking_model.dart';
import 'package:flutter/material.dart';

extension BookingStatusUI on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.awaitingPayment:
        return 'AWAITING PAYMENT';

      case BookingStatus.pending:
        return 'PENDING';

      case BookingStatus.approved:
        return 'APPROVED';

      case BookingStatus.rejected:
        return 'REJECTED';

      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get description {
    switch (this) {
      case BookingStatus.awaitingPayment:
        return 'Waiting for payment confirmation';

      case BookingStatus.pending:
        return 'Waiting for driver response';

      case BookingStatus.approved:
        return 'Driver approved your booking';

      case BookingStatus.rejected:
        return 'Driver rejected your booking';

      case BookingStatus.cancelled:
        return 'Booking cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.awaitingPayment:
        return Colors.blueGrey;

      case BookingStatus.pending:
        return Colors.orange;

      case BookingStatus.approved:
        return Colors.green;

      case BookingStatus.rejected:
        return Colors.red;

      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }
}
