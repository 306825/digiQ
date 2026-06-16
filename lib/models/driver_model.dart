class DriverBalance {
  final double balance;

  DriverBalance({required this.balance});

  factory DriverBalance.fromJson(Map<String, dynamic> json) {
    return DriverBalance(
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

enum WithdrawalStatus { pending, settled, rejected }

class WithdrawalRequest {
  final String id;
  final double amount;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? settledAt;
  final String? adminNote;

  WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.settledAt,
    this.adminNote,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    WithdrawalStatus status;
    switch (json['status']) {
      case 'settled':
        status = WithdrawalStatus.settled;
        break;
      case 'rejected':
        status = WithdrawalStatus.rejected;
        break;
      default:
        status = WithdrawalStatus.pending;
    }

    return WithdrawalRequest(
      id: json['_id']?.toString() ?? '',
      amount: (json['amount'] as num).toDouble(),
      status: status,
      createdAt: DateTime.parse(json['createdAt']),
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'])
          : null,
      adminNote: json['adminNote'],
    );
  }
}
