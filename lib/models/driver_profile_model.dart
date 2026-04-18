import 'package:digiQ/models/driver_document.dart';

class DriverProfile {
  final String? residentialAddress;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? branchCode;
  final String? accountType;

  final DriverDocument? idDocument;
  final DriverDocument? driversLicense;
  final DriverDocument? permit;
  final DriverDocument? prdp;
  final DriverDocument? proofOfAddress;
  final DriverDocument? proofOfBanking;

  DriverProfile({
    this.residentialAddress,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.branchCode,
    this.accountType,
    this.idDocument,
    this.driversLicense,
    this.permit,
    this.prdp,
    this.proofOfAddress,
    this.proofOfBanking,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      residentialAddress: json['residentialAddress'],
      bankName: json['bankName'],
      accountName: json['accountName'],
      accountNumber: json['accountNumber'],
      branchCode: json['branchCode'],
      accountType: json['accountType'],
      idDocument: DriverDocument.fromJson(json['idDocument']),
      driversLicense: DriverDocument.fromJson(json['driversLicense']),
      permit: DriverDocument.fromJson(json['permit']),
      prdp: DriverDocument.fromJson(json['prdp']),
      proofOfAddress: DriverDocument.fromJson(json['proofOfAddress']),
      proofOfBanking: DriverDocument.fromJson(json['proofOfBanking']),
    );
  }
}
