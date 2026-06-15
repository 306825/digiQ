bool isValidEmail(String value) {
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r"@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
  return emailRegex.hasMatch(value.trim());
}

/// Returns an error message or null if the password is strong enough.
String? validatePassword(String value) {
  if (value.length < 8) return 'At least 8 characters required';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least one uppercase letter';
  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add at least one lowercase letter';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) return 'Add at least one special character (e.g. !@#\$)';
  return null;
}
