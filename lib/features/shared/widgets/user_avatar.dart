import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double size;

  const UserAvatar({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(context),
        ),
      );
    }
    return _initialsAvatar(context);
  }

  Widget _initialsAvatar(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      child: Text(
        _initials(displayName),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
