class VehicleModel {
  final String id;
  final String registrationNumber;
  final String? make;
  final String? model;
  final int? year;
  final int seats;
  final String status; // pending | approved | rejected

  const VehicleModel({
    required this.id,
    required this.registrationNumber,
    this.make,
    this.model,
    this.year,
    required this.seats,
    required this.status,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get displayName {
    final parts = [
      if (year != null) year.toString(),
      if (make != null) make!,
      if (model != null) model!,
    ];
    return parts.isNotEmpty
        ? '${parts.join(' ')} ($registrationNumber)'
        : registrationNumber;
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'] ?? json['id'] as String,
      registrationNumber: json['registrationNumber'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
