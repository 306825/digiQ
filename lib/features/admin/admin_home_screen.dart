import 'package:digiQ/features/admin/admin_incidents_screen.dart';
import 'package:digiQ/features/admin/widgets/admin_routes_tab.dart';
import 'package:digiQ/features/admin/widgets/admin_drivers_tab.dart';
import 'package:digiQ/providers/admin_drivers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:go_router/go_router.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(adminDriversProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.surface,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Theme.of(context).colorScheme.surface,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Drivers'),
              Tab(icon: Icon(Icons.alt_route), text: 'Routes'),
              Tab(icon: Icon(Icons.report), text: 'Incidents'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            AdminDriversTab(),
            AdminRoutesTab(),
            AdminIncidentsScreen(),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Driver Card
 * -------------------------------------------------------------------------- */

class StatusRow extends StatelessWidget {
  final bool isActive;
  final DriverVerificationStatus verificationStatus;

  const StatusRow({
    required this.isActive,
    required this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (!isActive) {
      statusColor = Colors.red;
      statusText = 'Inactive';
    } else if (verificationStatus == DriverVerificationStatus.approved) {
      statusColor = Colors.green;
      statusText = 'Verified';
    } else if (verificationStatus == DriverVerificationStatus.pending) {
      statusColor = Colors.orange;
      statusText = 'Pending';
    } else {
      statusColor = Colors.grey;
      statusText = 'Not verified';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool isActive;

  const StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    final label = isActive ? 'ACTIVE' : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Pending Chip
 * -------------------------------------------------------------------------- */

// class _PendingChip extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.orange.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Text(
//         'PENDING',
//         style: TextStyle(
//           color: Colors.orange,
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }

/* --------------------------------------------------------------------------
 * Empty + Error States
 * -------------------------------------------------------------------------- */
