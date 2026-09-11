/// Platform-wide totals for the admin reporting tab.
///
/// These figures exist to evidence transaction volume and flow when applying
/// to payment gateway providers, which is why money is tracked separately from
/// counts and why a rolling 30-day window is included alongside all-time
/// totals — providers usually ask for recent monthly volume.
///
/// Expected contract from `GET /admin/stats`:
///
/// ```json
/// {
///   "users":        { "passengers": 0, "drivers": 0, "driversVerified": 0, "fleetOwners": 0 },
///   "bookings":     { "total": 0, "confirmed": 0, "pending": 0, "cancelled": 0 },
///   "trips":        { "total": 0, "completed": 0, "cancelled": 0 },
///   "transactions": { "currency": "ZAR", "confirmedAmount": 0.0, "totalAmount": 0.0,
///                     "last30DaysAmount": 0.0, "last30DaysCount": 0 },
///   "generatedAt":  "2026-09-06T12:00:00.000Z"
/// }
/// ```
///
/// Every field is parsed defensively: a missing section or key yields zero
/// rather than throwing, so the tab still renders if the backend ships the
/// sections incrementally.
class AdminStats {
  final UserTotals users;
  final BookingTotals bookings;
  final TripTotals trips;
  final TransactionTotals transactions;
  final DateTime? generatedAt;

  const AdminStats({
    required this.users,
    required this.bookings,
    required this.trips,
    required this.transactions,
    this.generatedAt,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      users: UserTotals.fromJson(_section(json['users'])),
      bookings: BookingTotals.fromJson(_section(json['bookings'])),
      trips: TripTotals.fromJson(_section(json['trips'])),
      transactions:
          TransactionTotals.fromJson(_section(json['transactions'])),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }
}

Map<String, dynamic> _section(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;

class UserTotals {
  final int passengers;
  final int drivers;
  final int driversVerified;
  final int fleetOwners;

  const UserTotals({
    required this.passengers,
    required this.drivers,
    required this.driversVerified,
    required this.fleetOwners,
  });

  factory UserTotals.fromJson(Map<String, dynamic> json) => UserTotals(
        passengers: _int(json['passengers']),
        drivers: _int(json['drivers']),
        driversVerified: _int(json['driversVerified']),
        fleetOwners: _int(json['fleetOwners']),
      );

  int get total => passengers + drivers + fleetOwners;
}

class BookingTotals {
  final int total;
  final int confirmed;
  final int pending;
  final int cancelled;

  const BookingTotals({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.cancelled,
  });

  factory BookingTotals.fromJson(Map<String, dynamic> json) => BookingTotals(
        total: _int(json['total']),
        confirmed: _int(json['confirmed']),
        pending: _int(json['pending']),
        cancelled: _int(json['cancelled']),
      );
}

class TripTotals {
  final int total;
  final int completed;
  final int cancelled;

  const TripTotals({
    required this.total,
    required this.completed,
    required this.cancelled,
  });

  factory TripTotals.fromJson(Map<String, dynamic> json) => TripTotals(
        total: _int(json['total']),
        completed: _int(json['completed']),
        cancelled: _int(json['cancelled']),
      );
}

class TransactionTotals {
  /// ISO currency code; defaults to ZAR since the platform is South African.
  final String currency;

  /// Value of bookings the driver has confirmed — the figure that evidences
  /// real settled volume.
  final double confirmedAmount;

  /// Value of all bookings including pending and cancelled.
  final double totalAmount;

  final double last30DaysAmount;
  final int last30DaysCount;

  const TransactionTotals({
    required this.currency,
    required this.confirmedAmount,
    required this.totalAmount,
    required this.last30DaysAmount,
    required this.last30DaysCount,
  });

  factory TransactionTotals.fromJson(Map<String, dynamic> json) =>
      TransactionTotals(
        currency: json['currency']?.toString() ?? 'ZAR',
        confirmedAmount: _double(json['confirmedAmount']),
        totalAmount: _double(json['totalAmount']),
        last30DaysAmount: _double(json['last30DaysAmount']),
        last30DaysCount: _int(json['last30DaysCount']),
      );
}
