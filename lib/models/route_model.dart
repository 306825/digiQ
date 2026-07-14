class RouteModel {
  final String id;
  final String fromLabel;
  final String toLabel;
  final double? price;

  const RouteModel({
    required this.id,
    required this.fromLabel,
    required this.toLabel,
    this.price,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      fromLabel: json['fromLabel']?.toString() ?? '',
      toLabel: json['toLabel']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  String get label => '$fromLabel → $toLabel';
}
