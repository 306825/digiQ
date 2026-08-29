import 'package:digiQ/core/api/admin_api.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final _pendingManualPaymentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getPendingManualPayments();
});

class AdminPaymentsTab extends ConsumerWidget {
  const AdminPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(_pendingManualPaymentsProvider);

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load payments', style: GoogleFonts.dmSans()),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(_pendingManualPaymentsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 56, color: Colors.green.shade300),
                const SizedBox(height: 16),
                Text('No pending payments',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('All EFTs have been confirmed.',
                    style: GoogleFonts.dmSans(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(_pendingManualPaymentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _PaymentCard(payment: payments[i], onConfirmed: () {
                  ref.invalidate(_pendingManualPaymentsProvider);
                }),
          ),
        );
      },
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onConfirmed;

  const _PaymentCard({required this.payment, required this.onConfirmed});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _loading = false;

  Future<void> _confirm(WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Payment',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm that you have received R ${widget.payment['amount']?.toStringAsFixed(2) ?? '—'} '
          'with reference ${widget.payment['paymentReference'] ?? '—'}?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Confirm', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(adminApiProvider);
      await api.confirmManualPayment(widget.payment['id'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment confirmed — driver notified.',
              style: GoogleFonts.dmSans()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onConfirmed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.dmSans()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
    final ref = p['paymentReference'] as String? ?? '—';
    final name = p['passengerName'] as String? ?? 'Unknown';
    final seats = p['seatsBooked'] as int? ?? 1;
    final createdAt = p['createdAt'] != null
        ? DateFormat('dd MMM yyyy HH:mm')
            .format(DateTime.parse(p['createdAt']).toLocal())
        : '—';

    return Consumer(
      builder: (ctx, wRef, _) => Card(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text('Awaiting Confirmation',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Row(label: 'Reference', value: ref),
              _Row(label: 'Amount', value: 'R ${amount.toStringAsFixed(2)}'),
              _Row(label: 'Seats', value: '$seats'),
              _Row(label: 'Booked At', value: createdAt),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: _loading ? null : () => _confirm(wRef),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm Payment Received'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
