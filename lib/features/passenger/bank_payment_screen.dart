import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digiQ/theme/app.theme.dart';

class BankPaymentScreen extends StatelessWidget {
  final String bookingId;
  final String paymentReference;
  final double amount;
  final Map<String, String?>? driverBankDetails;

  const BankPaymentScreen({
    super.key,
    required this.bookingId,
    required this.paymentReference,
    required this.amount,
    this.driverBankDetails,
  });

  void _copy(BuildContext context, String value, String label) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Amount Due',
                      style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('R ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Driver Banking Details',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            if (driverBankDetails == null ||
                driverBankDetails!.values.every((v) => v == null || v.isEmpty))
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
                  style: GoogleFonts.dmSans(color: Colors.orange.shade900),
                ),
              )
            else ...[
              if (driverBankDetails!['bankName']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Bank',
                  value: driverBankDetails!['bankName']!,
                  onCopy: () => _copy(context, driverBankDetails!['bankName']!, 'Bank name'),
                ),
              if (driverBankDetails!['accountName']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Name',
                  value: driverBankDetails!['accountName']!,
                  onCopy: () => _copy(context, driverBankDetails!['accountName']!, 'Account name'),
                ),
              if (driverBankDetails!['accountNumber']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Number',
                  value: driverBankDetails!['accountNumber']!,
                  onCopy: () => _copy(context, driverBankDetails!['accountNumber']!, 'Account number'),
                ),
              if (driverBankDetails!['accountType']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Account Type',
                  value: driverBankDetails!['accountType']!,
                ),
              if (driverBankDetails!['branchCode']?.isNotEmpty == true)
                _DetailTile(
                  label: 'Branch Code',
                  value: driverBankDetails!['branchCode']!,
                  onCopy: () => _copy(context, driverBankDetails!['branchCode']!, 'Branch code'),
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
                    'Without it we cannot link your payment to your booking.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.amber.shade900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          paymentReference,
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
                        onPressed: () =>
                            _copy(context, paymentReference, 'Payment reference'),
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
                    '1. Make an EFT to the account above using your reference number.',
                    '2. Tap "I\'ve Sent Payment" below.',
                    '3. Our team will verify your payment — this usually takes a few hours.',
                    '4. Once confirmed, your driver will be notified and can accept your booking.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(step,
                          style: GoogleFonts.dmSans(fontSize: 13, height: 1.4)),
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
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text("I've Sent Payment"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
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
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
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
