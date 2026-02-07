class DriverBalance {
  final double balance;

  DriverBalance({required this.balance});

  factory DriverBalance.fromJson(Map<String, dynamic> json) {
    return DriverBalance(
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
