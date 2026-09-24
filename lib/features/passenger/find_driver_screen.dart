import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/driver_follows_api.dart';
import 'package:strut/features/shared/widgets/user_avatar.dart';
import 'package:strut/models/driver_follow_model.dart';
import 'driver_public_profile_screen.dart';

class FindDriverScreen extends ConsumerStatefulWidget {
  const FindDriverScreen({super.key});

  @override
  ConsumerState<FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends ConsumerState<FindDriverScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  DriverCard? _result;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.length < 3) return;

    setState(() {
      _loading = true;
      _searched = false;
      _result = null;
    });

    try {
      final driver = await ref.read(driverFollowsApiProvider).searchDriver(q);
      setState(() {
        _result = driver;
        _searched = true;
      });
    } catch (_) {
      setState(() => _searched = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Driver')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Phone number or email address',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_searched && _result == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_search,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text(
                      'No driver found',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different phone number or email.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DriverResultCard(
                driver: _result!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DriverPublicProfileScreen(driverId: _result!.id),
                  ),
                ),
              ),
            )
          else if (!_searched)
            Expanded(
              child: Center(
                child: Text(
                  'Search by phone number or email to find a driver.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverResultCard extends StatelessWidget {
  final DriverCard driver;
  final VoidCallback onTap;

  const _DriverResultCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                displayName: driver.fullName,
                imageUrl: driver.profileImageUrl,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    if (driver.ratingCount > 0)
                      Text(
                        '⭐ ${driver.ratingAvg!.toStringAsFixed(1)} (${driver.ratingCount} reviews)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      Text(
                        'New driver',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    if (driver.following) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Following',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
