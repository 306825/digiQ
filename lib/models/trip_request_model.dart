enum TripRequestStatus {
  pendingDeposit,
  depositSent,
  depositConfirmed,
  tripLinked,
  cancelled,
}

enum DepositMethod { eft, payshap }

extension TripRequestStatusX on TripRequestStatus {
  String get value {
    switch (this) {
      case TripRequestStatus.pendingDeposit:   return 'pending_deposit';
      case TripRequestStatus.depositSent:      return 'deposit_sent';
      case TripRequestStatus.depositConfirmed: return 'deposit_confirmed';
      case TripRequestStatus.tripLinked:       return 'trip_linked';
      case TripRequestStatus.cancelled:        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case TripRequestStatus.pendingDeposit:   return 'Awaiting deposit';
      case TripRequestStatus.depositSent:      return 'Deposit sent';
      case TripRequestStatus.depositConfirmed: return 'Deposit confirmed';
      case TripRequestStatus.tripLinked:       return 'Trip ready';
      case TripRequestStatus.cancelled:        return 'Cancelled';
    }
  }

  static TripRequestStatus fromString(String s) {
    switch (s) {
      case 'deposit_sent':      return TripRequestStatus.depositSent;
      case 'deposit_confirmed': return TripRequestStatus.depositConfirmed;
      case 'trip_linked':       return TripRequestStatus.tripLinked;
      case 'cancelled':         return TripRequestStatus.cancelled;
      default:                  return TripRequestStatus.pendingDeposit;
    }
  }
}

class TripRequestModel {
  final String id;
  final String from;
  final String to;
  final String routeId;
  final String date;
  final int seatsNeeded;
  final TripRequestStatus status;
  final DepositMethod depositMethod;
  final String depositReference;
  final String? linkedTripId;
  final String? adminNotes;
  final DateTime createdAt;

  const TripRequestModel({
    required this.id,
    required this.from,
    required this.to,
    required this.routeId,
    required this.date,
    required this.seatsNeeded,
    required this.status,
    required this.depositMethod,
    required this.depositReference,
    this.linkedTripId,
    this.adminNotes,
    required this.createdAt,
  });

  factory TripRequestModel.fromJson(Map<String, dynamic> j) => TripRequestModel(
        id: j['id'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        routeId: j['routeId'] as String,
        date: j['date'] as String,
        seatsNeeded: j['seatsNeeded'] as int,
        status: TripRequestStatusX.fromString(j['status'] as String? ?? ''),
        depositMethod: (j['depositMethod'] as String?) == 'payshap'
            ? DepositMethod.payshap
            : DepositMethod.eft,
        depositReference: j['depositReference'] as String? ?? '',
        linkedTripId: j['linkedTripId'] as String?,
        adminNotes: j['adminNotes'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
