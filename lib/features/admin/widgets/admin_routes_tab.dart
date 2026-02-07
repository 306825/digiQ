import 'package:digiQ/providers/admin_routes_provider.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminRoutesTab extends ConsumerWidget {
  const AdminRoutesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(adminRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRouteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load routes')),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No routes defined yet',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(adminRoutesProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final route = routes[index];
                return ListTile(
                  leading: const Icon(Icons.route),
                  title: Text('${route.fromLabel} → ${route.toLabel}'),
                  subtitle: const Text('Immutable'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateRouteDialog(BuildContext context, WidgetRef ref) {
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromCtrl,
              decoration: const InputDecoration(labelText: 'From'),
            ),
            TextField(
              controller: toCtrl,
              decoration: const InputDecoration(labelText: 'To'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reverse route will be created automatically.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (fromCtrl.text.isEmpty || toCtrl.text.isEmpty) return;

              await ref
                  .read(adminRoutesProvider.notifier)
                  .createRoute(fromCtrl.text, toCtrl.text);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
