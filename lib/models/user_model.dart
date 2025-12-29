class UserModel {
  final String id;
  final String fullName;
  final List<String> roles;
  final bool isDriverVerified;

  UserModel({
    required this.id,
    required this.fullName,
    required this.roles,
    required this.isDriverVerified,
  });
}
