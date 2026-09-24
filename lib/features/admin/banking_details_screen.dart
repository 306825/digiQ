import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/banking_details_model.dart';
import 'package:strut/providers/banking_details_provider.dart';

class AdminBankingDetailsScreen extends ConsumerStatefulWidget {
  const AdminBankingDetailsScreen({super.key});

  @override
  ConsumerState<AdminBankingDetailsScreen> createState() =>
      _AdminBankingDetailsScreenState();
}

class _AdminBankingDetailsScreenState
    extends ConsumerState<AdminBankingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountName;
  late final TextEditingController _bankName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _branchCode;
  late final TextEditingController _payshapNumber;
  late final TextEditingController _notes;
  String _accountType = 'Current';

  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    _accountName.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _branchCode.dispose();
    _payshapNumber.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _populate(BankingDetails d) {
    if (_initialised) return;
    _accountName = TextEditingController(text: d.accountName);
    _bankName = TextEditingController(text: d.bankName);
    _accountNumber = TextEditingController(text: d.accountNumber);
    _branchCode = TextEditingController(text: d.branchCode);
    _payshapNumber = TextEditingController(text: d.payshapNumber);
    _notes = TextEditingController(text: d.notes);
    _accountType = d.accountType.isEmpty ? 'Current' : d.accountType;
    _initialised = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bankingDetailsProvider.notifier).save(
            BankingDetails(
              accountName: _accountName.text.trim(),
              bankName: _bankName.text.trim(),
              accountNumber: _accountNumber.text.trim(),
              branchCode: _branchCode.text.trim(),
              accountType: _accountType,
              payshapNumber: _payshapNumber.text.trim(),
              notes: _notes.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banking details saved'),
            backgroundColor: Colors.green,
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(bankingDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banking Details'),
        centerTitle: true,
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (details) {
          _populate(details);
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader('EFT Banking Details'),
            const SizedBox(height: 12),
            _Field(
              controller: _accountName,
              label: 'Account name',
              hint: 'e.g. Strut Technologies (Pty) Ltd',
              required: true,
            ),
            _Field(
              controller: _bankName,
              label: 'Bank',
              hint: 'e.g. FNB',
              required: true,
            ),
            _Field(
              controller: _accountNumber,
              label: 'Account number',
              hint: 'e.g. 62123456789',
              keyboard: TextInputType.number,
              required: true,
            ),
            _Field(
              controller: _branchCode,
              label: 'Branch / universal code',
              hint: 'e.g. 250655',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _accountType,
              decoration: _inputDec('Account type'),
              items: const [
                DropdownMenuItem(value: 'Current', child: Text('Current')),
                DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                DropdownMenuItem(
                    value: 'Transmission', child: Text('Transmission')),
              ],
              onChanged: (v) => setState(() => _accountType = v ?? 'Current'),
            ),

            const SizedBox(height: 24),
            _SectionHeader('PayShap'),
            const SizedBox(height: 12),
            _Field(
              controller: _payshapNumber,
              label: 'PayShap phone number',
              hint: 'e.g. 0821234567',
              keyboard: TextInputType.phone,
            ),

            const SizedBox(height: 24),
            _SectionHeader('Additional instructions'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: _inputDec('Notes shown to passenger')
                  .copyWith(hintText: 'e.g. Use your booking reference as payment reference'),
            ),

            const SizedBox(height: 32),

            // Preview card
            _PreviewCard(
              accountName: _accountName.text,
              bankName: _bankName.text,
              accountNumber: _accountNumber.text,
              branchCode: _branchCode.text,
              accountType: _accountType,
              payshapNumber: _payshapNumber.text,
              notes: _notes.text,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save banking details',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/* ── Helpers ─────────────────────────────────────────────── */

InputDecoration _inputDec(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final bool required;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboard,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: _inputDec(label).copyWith(hintText: hint),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.4,
      ),
    );
  }
}

/* ── Live preview card ───────────────────────────────────── */

class _PreviewCard extends StatelessWidget {
  final String accountName;
  final String bankName;
  final String accountNumber;
  final String branchCode;
  final String accountType;
  final String payshapNumber;
  final String notes;

  const _PreviewCard({
    required this.accountName,
    required this.bankName,
    required this.accountNumber,
    required this.branchCode,
    required this.accountType,
    required this.payshapNumber,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_balance_outlined,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Passenger preview',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary)),
          ]),
          const SizedBox(height: 10),
          if (accountName.isNotEmpty || bankName.isNotEmpty) ...[
            _Row('Account name', accountName),
            _Row('Bank', bankName),
            _Row('Account number', accountNumber),
            if (branchCode.isNotEmpty) _Row('Branch code', branchCode),
            _Row('Account type', accountType),
          ],
          if (payshapNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Row('PayShap', payshapNumber),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontStyle: FontStyle.italic)),
          ],
          if (accountName.isEmpty && bankName.isEmpty && payshapNumber.isEmpty)
            Text('No details entered yet.',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.7))),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer)),
            ),
          ),
        ],
      ),
    );
  }
}
