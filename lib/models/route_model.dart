class RouteModel {
  final String id;
  final String fromLabel;
  final String toLabel;
  final double? price;
  final double? netPricePerSeat;

  const RouteModel({
    required this.id,
    required this.fromLabel,
    required this.toLabel,
    this.price,
    this.netPricePerSeat,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      fromLabel: json['fromLabel']?.toString() ?? '',
      toLabel: json['toLabel']?.toString() ?? '',
      price: _parseDouble(json['price']),
      netPricePerSeat: _parseDouble(json['netPricePerSeat']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    // MongoDB extended JSON: { "$numberDecimal": "150" } or { "$numberDouble": "150" }
    if (value is Map) {
      final inner = value['\$numberDecimal'] ??
          value['\$numberDouble'] ??
          value['\$numberInt'] ??
          value['\$numberLong'];
      if (inner != null) return double.tryParse(inner.toString());
    }
    return double.tryParse(value.toString());
  }

  String get label => '$fromLabel → $toLabel';
}
