import 'package:strut/providers/admin_routes_provider.dart';
import 'package:strut/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminRoutesTab extends ConsumerWidget {
  const AdminRoutesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(adminRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Routes')),
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
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final route = routes[index];
                return ExpansionTile(
                  leading: const Icon(Icons.route),
                  title: Text('${route.fromLabel} → ${route.toLabel}'),
                  subtitle: Text(
                    route.dropoffs.isEmpty
                        ? 'No drop-offs set'
                        : '${route.dropoffs.length} drop-off${route.dropoffs.length == 1 ? '' : 's'} · From R${route.minPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: route.dropoffs.isEmpty ? Colors.red : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  children: route.dropoffs.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'No drop-offs configured. Edit this route to add them.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        ]
                      : route.dropoffs
                          .map((d) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                                title: Text(d.label),
                                trailing: Text(
                                  'R${d.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
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
    final dropoffs = <Map<String, TextEditingController>>[];

    void addDropoff(StateSetter setState) {
      setState(() {
        dropoffs.add({
          'label': TextEditingController(),
          'price': TextEditingController(),
        });
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Route'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: fromCtrl,
                  decoration: const InputDecoration(labelText: 'From'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: toCtrl,
                  decoration: const InputDecoration(labelText: 'To'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Drop-off points',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ...dropoffs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: d['label'],
                            decoration: InputDecoration(
                              labelText: 'Label ${i + 1}',
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: d['price'],
                            decoration: const InputDecoration(
                              labelText: 'Price (R)',
                              prefixText: 'R ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => setState(() => dropoffs.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => addDropoff(setState),
                  icon: const Icon(Icons.add),
                  label: const Text('Add drop-off'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reverse route is created automatically with the same drop-offs.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fromCtrl.text.isEmpty || toCtrl.text.isEmpty) return;
                if (dropoffs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one drop-off')),
                  );
                  return;
                }
                final parsedDropoffs = dropoffs.map((d) {
                  final label = d['label']!.text.trim();
                  final price = double.tryParse(d['price']!.text) ?? 0;
                  return {'label': label, 'price': price};
                }).toList();
                if (parsedDropoffs.any((d) => (d['label'] as String).isEmpty || (d['price'] as double) <= 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Each drop-off needs a label and a valid price')),
                  );
                  return;
                }
                await ref
                    .read(adminRoutesProvider.notifier)
                    .createRoute(fromCtrl.text, toCtrl.text, parsedDropoffs);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
