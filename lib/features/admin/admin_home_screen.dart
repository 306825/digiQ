import 'package:digiQ/features/admin/admin_incidents_screen.dart';
import 'package:digiQ/features/admin/widgets/admin_passenger_verifications_tab.dart';
import 'package:digiQ/features/admin/widgets/admin_payments_tab.dart';
import 'package:digiQ/features/admin/widgets/admin_payouts_tab.dart';
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
  int _selectedIndex = 0;

  static const _titles = [
    'Drivers',
    'Routes',
    'Incidents',
    'Payouts',
    'Passengers',
    'Payments',
  ];

  static const _items = [
    (icon: Icons.people, label: 'Drivers'),
    (icon: Icons.alt_route, label: 'Routes'),
    (icon: Icons.report, label: 'Incidents'),
    (icon: Icons.payments_outlined, label: 'Payouts'),
    (icon: Icons.verified_user_outlined, label: 'Passengers'),
    (icon: Icons.account_balance, label: 'Payments'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(adminDriversProvider));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primary),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < _items.length; i++)
              ListTile(
                leading: Icon(_items[i].icon,
                    color: _selectedIndex == i ? primary : null),
                title: Text(
                  _items[i].label,
                  style: TextStyle(
                    fontWeight: _selectedIndex == i
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: _selectedIndex == i ? primary : null,
                  ),
                ),
                selected: _selectedIndex == i,
                selectedTileColor: primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminDriversTab(),
          AdminRoutesTab(),
          AdminIncidentsScreen(),
          AdminPayoutsTab(),
          AdminPassengerVerificationsTab(),
          AdminPaymentsTab(),
        ],
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
            color: statusColor.withValues(alpha: 0.15),
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
        color: color.withValues(alpha: 0.15),
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
