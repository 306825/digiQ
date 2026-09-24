import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/banking_details_api.dart';
import 'package:strut/core/api/trip_requests_api.dart';
import 'package:strut/models/banking_details_model.dart';
import 'package:strut/models/route_model.dart';
import 'package:strut/models/trip_request_model.dart';

/// Entry point — shown instead of "no trips found".
class TripRequestScreen extends ConsumerStatefulWidget {
  final RouteModel route;
  final DateTime date;

  const TripRequestScreen({
    super.key,
    required this.route,
    required this.date,
  });

  @override
  ConsumerState<TripRequestScreen> createState() => _TripRequestScreenState();
}

class _TripRequestScreenState extends ConsumerState<TripRequestScreen> {
  int _seatsNeeded = 1;
  DepositMethod? _method;
  bool _loading = false;

  String get _dateStr {
    final d = widget.date;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _proceed() async {
    if (_method == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(tripRequestsApiProvider);
      final request = await api.create(
        routeId: widget.route.id,
        from: widget.route.fromLabel,
        to: widget.route.toLabel,
        date: _dateStr,
        seatsNeeded: _seatsNeeded,
        depositMethod: _method!,
      );

      if (!mounted) return;

      if (_method == DepositMethod.eft) {
        final banking = await ref.read(bankingDetailsApiProvider).passengerGet();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripRequestEftScreen(
              request: request,
              banking: banking,
            ),
          ),
        );
      } else {
        final banking = await ref.read(bankingDetailsApiProvider).passengerGet();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripRequestPayshapScreen(
              request: request,
              banking: banking,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${widget.date.day}/${widget.date.month}/${widget.date.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Trip'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.directions_car_rounded,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'No trips listed yet — we\'ll arrange one for you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay a 50% deposit to reserve your seat. We will confirm your trip within 24 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Route + date summary
            _SummaryRow(
                icon: Icons.route,
                label: 'Route',
                value: '${widget.route.fromLabel} → ${widget.route.toLabel}'),
            const SizedBox(height: 10),
            _SummaryRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateLabel),

            const SizedBox(height: 24),

            // Seat stepper
            Text('How many seats do you need?',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  onTap: _seatsNeeded > 1
                      ? () => setState(() => _seatsNeeded--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$_seatsNeeded',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  onTap: _seatsNeeded < 8
                      ? () => setState(() => _seatsNeeded++)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Payment method
            Text('Pay 50% deposit via',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _MethodCard(
              selected: _method == DepositMethod.eft,
              icon: Icons.account_balance_outlined,
              title: 'EFT / Bank transfer',
              subtitle: 'We\'ll show you our banking details',
              onTap: () => setState(() => _method = DepositMethod.eft),
            ),
            const SizedBox(height: 10),
            _MethodCard(
              selected: _method == DepositMethod.payshap,
              icon: Icons.phone_android,
              title: 'PayShap',
              subtitle: 'Instant payment via PayShap',
              onTap: () => setState(() => _method = DepositMethod.payshap),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_method != null && !_loading) ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── EFT payment screen ──────────────────────────────────── */

class TripRequestEftScreen extends ConsumerStatefulWidget {
  final TripRequestModel request;
  final BankingDetails banking;

  const TripRequestEftScreen({
    super.key,
    required this.request,
    required this.banking,
  });

  @override
  ConsumerState<TripRequestEftScreen> createState() =>
      _TripRequestEftScreenState();
}

class _TripRequestEftScreenState
    extends ConsumerState<TripRequestEftScreen> {
  bool _marking = false;
  bool _done = false;

  Future<void> _markSent() async {
    setState(() => _marking = true);
    try {
      final api = ref.read(tripRequestsApiProvider);
      await api.markDepositSent(widget.request.id);
      setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.banking;

    if (_done) return _SuccessScreen(from: widget.request.from, to: widget.request.to);

    return Scaffold(
      appBar: AppBar(title: const Text('EFT Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBox(
              'Transfer 50% of the trip fare to the account below.\nUse your reference number as payment reference.',
            ),
            const SizedBox(height: 20),
            _BankRow('Reference', widget.request.depositReference, copy: true),
            if (b.accountName.isNotEmpty) _BankRow('Account name', b.accountName),
            if (b.bankName.isNotEmpty) _BankRow('Bank', b.bankName),
            if (b.accountNumber.isNotEmpty)
              _BankRow('Account number', b.accountNumber, copy: true),
            if (b.branchCode.isNotEmpty) _BankRow('Branch code', b.branchCode),
            if (b.accountType.isNotEmpty) _BankRow('Account type', b.accountType),
            if (b.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(b.notes,
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic)),
            ],
            if (b.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Banking details not yet configured. Please contact Strut support.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _marking ? null : _markSent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _marking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('I\'ve sent the payment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── PayShap payment screen ──────────────────────────────── */

class TripRequestPayshapScreen extends ConsumerStatefulWidget {
  final TripRequestModel request;
  final BankingDetails banking;

  const TripRequestPayshapScreen({
    super.key,
    required this.request,
    required this.banking,
  });

  @override
  ConsumerState<TripRequestPayshapScreen> createState() =>
      _TripRequestPayshapScreenState();
}

class _TripRequestPayshapScreenState
    extends ConsumerState<TripRequestPayshapScreen> {
  bool _marking = false;
  bool _done = false;

  Future<void> _markSent() async {
    setState(() => _marking = true);
    try {
      await ref.read(tripRequestsApiProvider).markDepositSent(widget.request.id);
      setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.banking;
    if (_done) return _SuccessScreen(from: widget.request.from, to: widget.request.to);

    return Scaffold(
      appBar: AppBar(title: const Text('PayShap Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBox(
              'Send 50% of the trip fare via PayShap to the number below.\nUse your reference as the payment reference.',
            ),
            const SizedBox(height: 20),
            _BankRow('Reference', widget.request.depositReference, copy: true),
            if (b.payshapNumber.isNotEmpty)
              _BankRow('PayShap number', b.payshapNumber, copy: true)
            else
              const Text(
                'PayShap details not yet configured. Please contact Strut support.',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _marking ? null : _markSent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _marking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('I\'ve sent the payment',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Success screen ──────────────────────────────────────── */

class _SuccessScreen extends StatelessWidget {
  final String from;
  final String to;
  const _SuccessScreen({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Request received!',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ve noted your trip from $from to $to. '
                  'Once we confirm your deposit, we\'ll arrange a driver and notify you right away.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ── Shared widgets ──────────────────────────────────────── */

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : null)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: Colors.blue.shade900)),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copy;
  const _BankRow(this.label, this.value, {this.copy = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (copy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.copy, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
