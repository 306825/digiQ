import 'package:digiQ/core/api/booking_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digiQ/theme/app.theme.dart';

class BankPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String paymentReference;
  final double amount;
  final Map<String, String?>? driverBankDetails;
  final String? payshapId;

  const BankPaymentScreen({
    super.key,
    required this.bookingId,
    required this.paymentReference,
    required this.amount,
    this.driverBankDetails,
    this.payshapId,
  });

  @override
  ConsumerState<BankPaymentScreen> createState() => _BankPaymentScreenState();
}

class _BankPaymentScreenState extends ConsumerState<BankPaymentScreen> {
  bool _submitting = false;

  Future<void> _reportPaymentSent() async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(bookingApiProvider);
      await api.reportPaymentSent(widget.bookingId);
    } catch (_) {
      // Non-critical — navigate home regardless; booking state updated server-side
    } finally {
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bank = widget.driverBankDetails;
    final hasBank =
        bank != null && bank.values.any((v) => v != null && v.isNotEmpty);
    final hasPayshap = (widget.payshapId ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount banner ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Amount Due',
                      style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('R ${widget.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── PayShap (shown first when available) ───────────────────────
            if (hasPayshap) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 6),
                        Text('Pay with PayShap',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.green.shade800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Recommended',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PayShap reflects immediately — the driver can confirm your booking right away.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: Colors.green.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PayShap ID',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600)),
                              Text(widget.payshapId!,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green.shade900,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          color: Colors.green.shade700,
                          tooltip: 'Copy PayShap ID',
                          onPressed: () => _copy(widget.payshapId!, 'PayShap ID'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use reference: ${widget.paymentReference}',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or pay by EFT',
                        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],

            Text('Driver Banking Details',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            if (!hasBank)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Driver banking details are not available. '
                  'Please contact support to complete your payment.',
                  style:
                      GoogleFonts.dmSans(color: Colors.orange.shade900),
                ),
              )
            else ...[
              if (bank!['bankName']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Bank',
                  value: bank['bankName']!,
                  onCopy: () => _copy(bank['bankName']!, 'Bank name'),
                ),
              if (bank['accountName']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Name',
                  value: bank['accountName']!,
                  onCopy: () =>
                      _copy(bank['accountName']!, 'Account name'),
                ),
              if (bank['accountNumber']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Number',
                  value: bank['accountNumber']!,
                  onCopy: () =>
                      _copy(bank['accountNumber']!, 'Account number'),
                ),
              if (bank['accountType']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Type',
                  value: bank['accountType']!,
                ),
              if (bank['branchCode']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Branch Code',
                  value: bank['branchCode']!,
                  onCopy: () =>
                      _copy(bank['branchCode']!, 'Branch code'),
                ),
            ],

            const SizedBox(height: 20),

            // ── Reference ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text('Payment Reference',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You MUST use this exact reference when making the payment. '
                    'Without it the driver cannot link your payment to your booking.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.amber.shade900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.paymentReference,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        color: Colors.amber.shade800,
                        tooltip: 'Copy reference',
                        onPressed: () => _copy(
                            widget.paymentReference, 'Payment reference'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Instructions ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  for (final step in [
                    '1. Make an EFT to the driver\'s account above using your reference number.',
                    '2. Tap "I\'ve Sent Payment" below.',
                    '3. The driver will receive a notification to review and approve your booking.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(step,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, height: 1.4)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── CTA ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                onPressed: _submitting ? null : _reportPaymentSent,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("I've Sent Payment"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Text('Pay Later',
                    style: GoogleFonts.dmSans(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _DetailTile({required this.label, required this.value, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: ListTile(
        dense: true,
        title: Text(label,
            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey)),
        subtitle: Text(value,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87)),
        trailing: onCopy != null
            ? IconButton(
                icon: const Icon(Icons.copy, size: 18),
                color: Colors.grey,
                onPressed: onCopy,
              )
            : null,
      ),
    );
  }
}
