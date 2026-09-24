class BankingDetails {
  final String accountName;
  final String bankName;
  final String accountNumber;
  final String branchCode;
  final String accountType;
  final String payshapNumber;
  final String notes;

  const BankingDetails({
    required this.accountName,
    required this.bankName,
    required this.accountNumber,
    required this.branchCode,
    required this.accountType,
    required this.payshapNumber,
    required this.notes,
  });

  factory BankingDetails.empty() => const BankingDetails(
        accountName: '',
        bankName: '',
        accountNumber: '',
        branchCode: '',
        accountType: 'Current',
        payshapNumber: '',
        notes: '',
      );

  factory BankingDetails.fromJson(Map<String, dynamic> j) => BankingDetails(
        accountName: j['accountName'] as String? ?? '',
        bankName: j['bankName'] as String? ?? '',
        accountNumber: j['accountNumber'] as String? ?? '',
        branchCode: j['branchCode'] as String? ?? '',
        accountType: j['accountType'] as String? ?? 'Current',
        payshapNumber: j['payshapNumber'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'accountName': accountName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'branchCode': branchCode,
        'accountType': accountType,
        'payshapNumber': payshapNumber,
        'notes': notes,
      };

  bool get isEmpty =>
      accountName.isEmpty &&
      bankName.isEmpty &&
      accountNumber.isEmpty &&
      payshapNumber.isEmpty;
}
