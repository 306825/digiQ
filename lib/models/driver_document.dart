class DriverDocument {
  final String? fileUrl;

  DriverDocument({this.fileUrl});

  factory DriverDocument.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverDocument();

    return DriverDocument(
      fileUrl: json['fileUrl'],
    );
  }
}
