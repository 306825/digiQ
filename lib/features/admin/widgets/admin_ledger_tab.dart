import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_providers.dart';

final adminLedgerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getLedger();
});

class AdminLedgerTab extends ConsumerWidget {
  const AdminLedgerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(adminLedgerProvider);

    return ledgerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load ledger: $e')),
      data: (data) {
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        final entries = (data['entries'] as List?) ?? [];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminLedgerProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(summary: summary),
              const SizedBox(height: 16),
              Text(
                'Transactions (${entries.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...entries.map((e) => _LedgerEntryCard(entry: e as Map<String, dynamic>)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final credits = (summary['totalCredits'] as num?)?.toDouble() ?? 0;
    final debits = (summary['totalDebits'] as num?)?.toDouble() ?? 0;
    final net = (summary['netBalance'] as num?)?.toDouble() ?? 0;
    final count = (summary['entryCount'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ledger Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatTile('Total Credits', 'R ${credits.toStringAsFixed(2)}', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _StatTile('Total Debits', 'R ${debits.toStringAsFixed(2)}', Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _StatTile('Net Balance', 'R ${net.toStringAsFixed(2)}', net >= 0 ? Colors.blue : Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _StatTile('Entries', '$count', Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _LedgerEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _LedgerEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final type = entry['type'] as String? ?? '';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final description = entry['description'] as String? ?? '';
    final settled = entry['settled'] as bool? ?? false;
    final driver = entry['driver'] as Map<String, dynamic>?;
    final booking = entry['booking'] as Map<String, dynamic>?;
    final createdAt = entry['createdAt'] != null
        ? DateTime.tryParse(entry['createdAt'].toString())
        : null;

    final isCredit = type == 'credit';
    final isPayout = type == 'payout';
    final color = isCredit ? Colors.green : (isPayout ? Colors.blue : Colors.red);
    final sign = isCredit ? '+' : '-';
    final icon = isCredit ? Icons.arrow_downward : (isPayout ? Icons.send : Icons.arrow_upward);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        '$sign R ${amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                  if (driver != null) ...[
                    const SizedBox(height: 4),
                    Text(driver['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(driver['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                  if (booking != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.receipt_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(booking['reference'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace')),
                        const SizedBox(width: 8),
                        Text('• ${booking['passenger'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (settled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SETTLED', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      if (createdAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
