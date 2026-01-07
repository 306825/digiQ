import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'package:flutter/foundation.dart';

class DriverVerificationScreen extends ConsumerWidget {
  const DriverVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = user.verificationStatus;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your driver account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(_descriptionFor(status)),

            const SizedBox(height: 24),

            const _RequirementTile(
              icon: Icons.badge,
              text: 'Valid driver’s license',
            ),
            const _RequirementTile(
              icon: Icons.directions_car,
              text: 'Vehicle details',
            ),
            const _RequirementTile(
              icon: Icons.assignment_turned_in,
              text: 'Proof of ownership or permission',
            ),
            // 🧪 DEBUG CONTROLS (REMOVE BEFORE PRODUCTION)
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Debug Controls',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(authProvider.notifier)
                            .approveDriverVerification();
                      },
                      child: const Text('Approve Verification'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(authProvider.notifier)
                            .rejectDriverVerification();
                      },
                      child: const Text('Reject Verification'),
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit(status)
                    ? () async {
                        ref
                            .read(authProvider.notifier)
                            .submitDriverVerification();
                      }
                    : null,
                child: Text(_buttonLabelFor(status)),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('DEBUG: Logout (Clear Local Auth)'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSubmit(DriverVerificationStatus status) {
    return status == DriverVerificationStatus.none ||
        status == DriverVerificationStatus.rejected;
  }

  String _buttonLabelFor(DriverVerificationStatus status) {
    switch (status) {
      case DriverVerificationStatus.none:
        return 'Submit for Verification';
      case DriverVerificationStatus.pending:
        return 'Verification Under Review';
      case DriverVerificationStatus.approved:
        return 'Driver Verified';
      case DriverVerificationStatus.rejected:
        return 'Resubmit Verification';
    }
  }

  String _descriptionFor(DriverVerificationStatus status) {
    switch (status) {
      case DriverVerificationStatus.none:
        return 'To accept booking requests, we need to verify your '
            'driver details.';
      case DriverVerificationStatus.pending:
        return 'Your verification documents have been submitted and are '
            'currently under review.';
      case DriverVerificationStatus.approved:
        return 'Your driver account has been verified. You can now accept '
            'booking requests.';
      case DriverVerificationStatus.rejected:
        return 'Your verification was rejected. Please review your details '
            'and resubmit.';
    }
  }
}

class _RequirementTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequirementTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
