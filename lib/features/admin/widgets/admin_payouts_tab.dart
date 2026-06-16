import 'package:digiQ/core/api/admin_api.dart';
import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final pendingPayoutsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getPendingPayouts();
});

class AdminPayoutsTab extends ConsumerWidget {
  const AdminPayoutsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(pendingPayoutsProvider);

    return payoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load payouts')),
      data: (payouts) {
        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_outlined,
                    size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No pending payouts',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'All driver withdrawal requests have been processed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingPayoutsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PayoutRequestTile(payout: payouts[i]),
          ),
        );
      },
    );
  }
}

class _PayoutRequestTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> payout;

  const _PayoutRequestTile({required this.payout});

  @override
  ConsumerState<_PayoutRequestTile> createState() =>
      _PayoutRequestTileState();
}

class _PayoutRequestTileState extends ConsumerState<_PayoutRequestTile> {
  bool _loading = false;

  Map<String, dynamic> get p => widget.payout;

  String get _driverName {
    final driver = p['driver'] as Map<String, dynamic>?;
    return driver?['fullName']?.toString() ?? 'Unknown driver';
  }

  Map<String, dynamic> get _bank =>
      (p['bankSnapshot'] as Map<String, dynamic>?) ?? {};

  Future<void> _settle() async {
    final confirmed = await _confirm(
      context,
      title: 'Settle Payout',
      message:
          'Confirm that you have transferred R ${_amount.toStringAsFixed(2)} to $_driverName.\n\nThis will mark the request as paid and deduct from their balance.',
      actionLabel: 'Mark as Paid',
      actionColor: AppTheme.success,
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(adminApiProvider);
      await api.settleWithdrawal(p['_id'].toString());
      ref.invalidate(pendingPayoutsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to settle payout')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Optional: add a reason for the driver.'),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(adminApiProvider);
      await api.rejectWithdrawal(p['_id'].toString(),
          adminNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
      ref.invalidate(pendingPayoutsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject payout')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _amount => (p['amount'] as num).toDouble();

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy · HH:mm');
    final createdAt = p['createdAt'] != null
        ? fmt.format(DateTime.parse(p['createdAt']))
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      createdAt,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                'R ${_amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B2E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Bank details ─────────────────────────────────────────────────
          const Text(
            'Bank Details',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF56687A)),
          ),
          const SizedBox(height: 8),
          _BankRow(label: 'Bank', value: _bank['bankName'] ?? '-'),
          _BankRow(label: 'Account name', value: _bank['accountName'] ?? '-'),
          _BankRow(
              label: 'Account number', value: _bank['accountNumber'] ?? '-'),
          if ((_bank['branchCode'] ?? '').isNotEmpty)
            _BankRow(label: 'Branch code', value: _bank['branchCode']),
          if ((_bank['accountType'] ?? '').isNotEmpty)
            _BankRow(label: 'Account type', value: _bank['accountType']),

          const SizedBox(height: 16),

          // ── Actions ──────────────────────────────────────────────────────
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: BorderSide(
                              color: AppTheme.danger.withOpacity(0.5)),
                        ),
                        onPressed: _reject,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark as Paid'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success),
                        onPressed: _settle,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: actionColor),
                onPressed: () => Navigator.pop(context, true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF56687A)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
