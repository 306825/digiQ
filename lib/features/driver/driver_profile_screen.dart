import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:digiQ/features/shared/widgets/avatar_picker.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _banks = [
  'ABSA',
  'Capitec',
  'FNB',
  'Investec',
  'Nedbank',
  'Standard Bank',
  'TymeBank',
  'African Bank',
];

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCodeCtrl = TextEditingController();

  String? _bankName;
  String _accountType = 'cheque';
  bool _saving = false;
  bool _populated = false;

  // Tracks the S3 key set after a bank letter upload in this session
  String? _pendingBankDocKey;

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _branchCodeCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile() {
    if (_populated) return;
    final profile = ref.read(authProvider).user?.driverProfile;
    if (profile == null) return;
    _bankName = _banks.contains(profile.bankName) ? profile.bankName : null;
    _accountNameCtrl.text = profile.accountName ?? '';
    _accountNumberCtrl.text = profile.accountNumber ?? '';
    _branchCodeCtrl.text = profile.branchCode ?? '';
    _accountType = profile.accountType ?? 'cheque';
    _populated = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bankName == null) {
      _snack('Please select your bank');
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(driverApiProvider);
      await api.updateBankDetails(
        bankName: _bankName!,
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        branchCode: _branchCodeCtrl.text.trim().isEmpty
            ? null
            : _branchCodeCtrl.text.trim(),
        accountType: _accountType,
        proofOfBankingUrl: _pendingBankDocKey,
      );
      await ref.read(authProvider.notifier).refreshMe();
      if (!mounted) return;
      setState(() => _pendingBankDocKey = null);
      _snack('Profile saved', success: true);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: success ? Colors.green : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    _populateFromProfile();

    final profile = user?.driverProfile;
    final hasBankDoc = _pendingBankDocKey != null ||
        (profile?.proofOfBanking?.fileUrl?.isNotEmpty == true);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────────────
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    const AvatarPicker(),
                    const SizedBox(height: 10),
                    Text(
                      user?.fullName ?? '',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const _Divider(),
              const SizedBox(height: 20),

              // ── Personal info ─────────────────────────────────────────────
              _SectionHeader('Personal Information'),
              const SizedBox(height: 12),
              _InfoTile(label: 'Full Name', value: user?.fullName ?? '—'),
              _InfoTile(label: 'Email', value: user?.email ?? '—'),
              if (profile?.residentialAddress != null &&
                  profile!.residentialAddress!.isNotEmpty)
                _InfoTile(
                    label: 'Address', value: profile.residentialAddress!),

              const SizedBox(height: 24),
              const _Divider(),
              const SizedBox(height: 20),

              // ── Banking details ───────────────────────────────────────────
              _SectionHeader('Banking Details'),
              const SizedBox(height: 4),
              Text(
                'Shown to passengers when they book your trips.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _bankName,
                decoration: _inputDec('Bank *'),
                items: _banks
                    .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, style: GoogleFonts.dmSans())))
                    .toList(),
                onChanged: (v) => setState(() => _bankName = v),
                validator: (_) =>
                    _bankName == null ? 'Please select your bank' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _accountNameCtrl,
                decoration: _inputDec('Account Holder Name *'),
                style: GoogleFonts.dmSans(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Account holder name is required'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _accountNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('Account Number *'),
                style: GoogleFonts.dmSans(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Account number is required'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _branchCodeCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('Branch Code (optional)'),
                style: GoogleFonts.dmSans(),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: _inputDec('Account Type *'),
                items: const [
                  DropdownMenuItem(
                      value: 'cheque', child: Text('Cheque Account')),
                  DropdownMenuItem(
                      value: 'savings', child: Text('Savings Account')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _accountType = v);
                },
              ),

              const SizedBox(height: 20),

              // ── Bank confirmation letter ───────────────────────────────────
              _SectionHeader('Bank Confirmation Letter'),
              const SizedBox(height: 4),
              Text(
                'Upload a bank-issued letter confirming your account details.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              DocumentUploadTile(
                title: 'Bank Confirmation Letter',
                type: 'bank',
                uploaded: hasBankDoc,
                onUploaded: (key) {
                  setState(() => _pendingBankDocKey = key);
                  _snack('Letter uploaded — tap Save to confirm', success: true);
                },
              ),

              const SizedBox(height: 32),

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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.grey.shade200, height: 1);
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
