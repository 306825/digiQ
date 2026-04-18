import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/providers/admin_drivers_provider.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(adminDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Manage Drivers',
            icon: const Icon(Icons.people),
            onPressed: () {
              context.go('/admin/drivers');
            },
          ),
        ],
      ),
      body: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        //error: (_, __) => const Center(child: Text('Failed to load drivers')),
        error: (error, stack) {
          debugPrint("❌ DRIVER LOAD ERROR: $error");
          debugPrint("STACK: $stack");

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load drivers\n\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
        data: (drivers) {
          if (drivers.isEmpty) {
            return const Center(child: Text('No drivers found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(adminDriversProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                return _DriverTile(driver: drivers[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DriverTile extends ConsumerWidget {
  final UserModel driver;

  const _DriverTile({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminDriversProvider.notifier);

    final isActive = driver.isActive ?? true;

    return Card(
      child: ListTile(
        title: Text(driver.fullName),
        subtitle: Text(
          'Status: ${driver.verificationStatus.name.toUpperCase()}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(isActive: isActive),
            const SizedBox(width: 12),
            if (isActive)
              OutlinedButton(
                onPressed: () async {
                  await notifier.deactivate(driver.id);
                },
                child: const Text('Deactivate'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  await notifier.activate(driver.id);
                },
                child: const Text('Activate'),
              ),
            if (driver.verificationStatus == DriverVerificationStatus.pending)
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(adminDriversProvider.notifier)
                      .approve(driver.id);
                },
                child: const Text("Approve"),
              ),
            if (driver.verificationStatus == DriverVerificationStatus.pending)
              OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(adminDriversProvider.notifier)
                      .reject(driver.id);
                },
                child: const Text("Reject"),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    final label = isActive ? 'ACTIVE' : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
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

class AdminDriversNotifier extends AsyncNotifier<List<UserModel>> {
  /* --------------------------------------------------------------------------
   * LOAD ALL DRIVERS
   * -------------------------------------------------------------------------- */
  @override
  Future<List<UserModel>> build() async {
    print('🔥 ADMIN DRIVERS PROVIDER BUILD CALLED');

    final api = ref.read(adminApiProvider);
    final response = await api.getDrivers();

    final List list = response.data;

    print("📦 DRIVERS RAW = $list");

    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  /* --------------------------------------------------------------------------
   * REFRESH
   * -------------------------------------------------------------------------- */
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /* --------------------------------------------------------------------------
   * APPROVE DRIVER
   * -------------------------------------------------------------------------- */
  Future<void> approve(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.approveDriver(driverId);
    await refresh();
  }

  /* --------------------------------------------------------------------------
   * REJECT DRIVER
   * -------------------------------------------------------------------------- */
  Future<void> reject(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.rejectDriver(driverId);
    await refresh();
  }

  /* --------------------------------------------------------------------------
   * DEACTIVATE DRIVER
   * -------------------------------------------------------------------------- */
  Future<void> deactivate(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.deactivateDriver(driverId);
    await refresh();
  }

  /* --------------------------------------------------------------------------
   * ACTIVATE DRIVER
   * -------------------------------------------------------------------------- */
  Future<void> activate(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.activateDriver(driverId);
    await refresh();
  }
}

final adminDriversProvider =
    AsyncNotifierProvider<AdminDriversNotifier, List<UserModel>>(
        AdminDriversNotifier.new);
