import 'package:digiQ/features/passenger/passenger_identity_verification_screen.dart';
import 'package:digiQ/features/shared/widgets/avatar_picker.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PassengerProfileScreen extends ConsumerStatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  ConsumerState<PassengerProfileScreen> createState() =>
      _PassengerProfileScreenState();
}

class _PassengerProfileScreenState
    extends ConsumerState<PassengerProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).refreshMe());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final verStatus = user.passengerVerificationStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const AvatarPicker(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.edit, size: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              user.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 4),

            Text(
              user.email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            if (verStatus == PassengerVerificationStatus.approved) ...[
              const SizedBox(height: 12),
              _VerifiedBadge(),
            ],

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            // Identity verification card
            _VerificationCard(status: verStatus),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Verified badge
 * -------------------------------------------------------------------------- */

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            'Identity Verified',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Verification card — changes based on status
 * -------------------------------------------------------------------------- */

class _VerificationCard extends StatelessWidget {
  final PassengerVerificationStatus status;

  const _VerificationCard({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == PassengerVerificationStatus.approved) {
      return _infoTile(
        context,
        icon: Icons.verified_user,
        iconColor: Colors.green,
        title: 'Identity Verified',
        body:
            'Your identity has been verified. A verified badge is shown to drivers when you request a booking.',
        trailing: null,
      );
    }

    if (status == PassengerVerificationStatus.pending) {
      return _infoTile(
        context,
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.orange,
        title: 'Verification Pending',
        body:
            'We\'ve received your selfie and are reviewing it. This usually takes less than 24 hours.',
        trailing: null,
      );
    }

    final isRejected = status == PassengerVerificationStatus.rejected;

    return _infoTile(
      context,
      icon: isRejected ? Icons.error_outline : Icons.badge_outlined,
      iconColor: isRejected ? Colors.red : Colors.blueGrey,
      title: isRejected ? 'Verification Failed' : 'Verify Your Identity',
      body: isRejected
          ? 'Your verification was not approved. Please take a new selfie clearly showing your face and ID document, then try again.'
          : 'Take a selfie holding your government-issued ID. Once approved, a verified badge will appear next to your name.',
      trailing: FilledButton.icon(
        icon: const Icon(Icons.camera_alt_outlined, size: 18),
        label: Text(isRejected ? 'Try Again' : 'Verify Now'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PassengerIdentityVerificationScreen(),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
          if (trailing != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: trailing),
          ],
        ],
      ),
    );
  }
}
