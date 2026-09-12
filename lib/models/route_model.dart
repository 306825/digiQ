class RouteDropoff {
  final String label;
  final double price;
  final double? netPrice;

  const RouteDropoff({
    required this.label,
    required this.price,
    this.netPrice,
  });

  factory RouteDropoff.fromJson(Map<String, dynamic> json) {
    return RouteDropoff(
      label: json['label']?.toString() ?? '',
      price: _parseDouble(json['price']) ?? 0,
      netPrice: _parseDouble(json['netPrice']),
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'price': price};

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class RouteModel {
  final String id;
  final String fromLabel;
  final String toLabel;
  final List<RouteDropoff> dropoffs;

  const RouteModel({
    required this.id,
    required this.fromLabel,
    required this.toLabel,
    required this.dropoffs,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rawDropoffs = json['dropoffs'];
    final dropoffs = rawDropoffs is List
        ? rawDropoffs
            .whereType<Map<String, dynamic>>()
            .map((d) => RouteDropoff.fromJson(d))
            .toList()
        : <RouteDropoff>[];
    return RouteModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      fromLabel: json['fromLabel']?.toString() ?? '',
      toLabel: json['toLabel']?.toString() ?? '',
      dropoffs: dropoffs,
    );
  }

  double? get minPrice =>
      dropoffs.isEmpty ? null : dropoffs.map((d) => d.price).reduce((a, b) => a < b ? a : b);

  String get label => '$fromLabel → $toLabel';
}
