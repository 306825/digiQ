class RouteModel {
  final String id;
  final String fromLabel;
  final String toLabel;

  const RouteModel({
    required this.id,
    required this.fromLabel,
    required this.toLabel,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['_id'],
      fromLabel: json['fromLabel'],
      toLabel: json['toLabel'],
    );
  }

  String get label => '$fromLabel → $toLabel';
}
