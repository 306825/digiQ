import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/driver_vehicle_screen.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:digiQ/features/shared/widgets/avatar_picker.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/models/vehicle_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/driver_vehicle_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style:
                GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

// ── Horizontal rule ───────────────────────────────────────────────────────────

class _Rule extends StatelessWidget {
  const _Rule();
  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.grey.shade200, height: 1);
}

// ── Read-only info row ────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final vehiclesAsync = ref.watch(driverVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: Text('Log out', style: GoogleFonts.dmSans(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverVehicleProvider);
          await ref.read(authProvider.notifier).refreshMe();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const AvatarPicker(),
                  const SizedBox(height: 10),
                  Text(
                    user?.fullName ?? '—',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const _Rule(),
            const SizedBox(height: 20),

            // ── Verification status ───────────────────────────────────────
            _SectionHeader('Verification'),
            _VerificationCard(status: user?.verificationStatus),

            const SizedBox(height: 24),
            const _Rule(),
            const SizedBox(height: 20),

            // ── Personal info ─────────────────────────────────────────────
            _SectionHeader('Personal Information'),
            _InfoTile(label: 'Full Name', value: user?.fullName ?? '—'),
            _InfoTile(label: 'Email', value: user?.email ?? '—'),
            if ((user?.driverProfile?.residentialAddress ?? '').isNotEmpty)
              _InfoTile(
                  label: 'Address',
                  value: user?.driverProfile?.residentialAddress ?? ''),

            const SizedBox(height: 24),
            const _Rule(),
            const SizedBox(height: 20),

            // ── Banking details ───────────────────────────────────────────
            _BankingSection(ref: ref),

            const SizedBox(height: 24),
            const _Rule(),
            const SizedBox(height: 20),

            // ── Vehicles ──────────────────────────────────────────────────
            _SectionHeader('My Vehicles'),
            vehiclesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load vehicles'),
              data: (vehicles) =>
                  _VehiclesSection(vehicles: vehicles, ref: ref),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verification status card
// ─────────────────────────────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  final DriverVerificationStatus? status;
  const _VerificationCard({this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, subtitle) = switch (status) {
      DriverVerificationStatus.approved => (
          AppTheme.success,
          Icons.verified_outlined,
          'Verified',
          'Your account is fully verified',
        ),
      DriverVerificationStatus.pending => (
          AppTheme.warning,
          Icons.hourglass_top_outlined,
          'Under Review',
          'Your documents are being reviewed',
        ),
      DriverVerificationStatus.rejected => (
          AppTheme.danger,
          Icons.cancel_outlined,
          'Rejected',
          'Please resubmit your documents',
        ),
      _ => (
          Colors.grey,
          Icons.info_outline,
          'Not Verified',
          'Complete verification to accept bookings',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banking section — display mode if details exist, edit form if not
// ─────────────────────────────────────────────────────────────────────────────

class _BankingSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _BankingSection({required this.ref});

  @override
  ConsumerState<_BankingSection> createState() => _BankingSectionState();
}

class _BankingSectionState extends ConsumerState<_BankingSection> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).user?.driverProfile;
    final hasDetails = profile != null &&
        (profile.bankName?.isNotEmpty == true) &&
        (profile.accountNumber?.isNotEmpty == true);

    if (!hasDetails || _editing) {
      return _BankEditForm(
        initialBankName: profile?.bankName,
        initialAccountName: profile?.accountName ?? '',
        initialAccountNumber: profile?.accountNumber ?? '',
        initialBranchCode: profile?.branchCode ?? '',
        initialAccountType: profile?.accountType ?? 'cheque',
        hasExistingBankDoc: profile?.proofOfBanking?.fileUrl?.isNotEmpty == true,
        onSaved: () => setState(() => _editing = false),
        onCancel: hasDetails ? () => setState(() => _editing = false) : null,
      );
    }

    // ── Display mode ──────────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Banking Details',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('Edit', style: GoogleFonts.dmSans(fontSize: 13)),
              onPressed: () => setState(() => _editing = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _InfoTile(label: 'Bank', value: profile.bankName ?? '—'),
        _InfoTile(
            label: 'Acc Name', value: profile.accountName ?? '—'),
        _InfoTile(
            label: 'Acc Number', value: profile.accountNumber ?? '—'),
        if ((profile.branchCode ?? '').isNotEmpty)
          _InfoTile(label: 'Branch', value: profile.branchCode!),
        _InfoTile(
          label: 'Acc Type',
          value: profile.accountType == 'savings'
              ? 'Savings Account'
              : 'Cheque Account',
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: profile.proofOfBanking?.fileUrl?.isNotEmpty == true
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: profile.proofOfBanking?.fileUrl?.isNotEmpty == true
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                profile.proofOfBanking?.fileUrl?.isNotEmpty == true
                    ? Icons.check_circle_outline
                    : Icons.upload_file_outlined,
                size: 18,
                color: profile.proofOfBanking?.fileUrl?.isNotEmpty == true
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.proofOfBanking?.fileUrl?.isNotEmpty == true
                      ? 'Bank confirmation letter on file'
                      : 'No bank confirmation letter — tap Edit to upload',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banking edit form (used both for first-time capture and editing)
// ─────────────────────────────────────────────────────────────────────────────

class _BankEditForm extends ConsumerStatefulWidget {
  final String? initialBankName;
  final String initialAccountName;
  final String initialAccountNumber;
  final String initialBranchCode;
  final String initialAccountType;
  final bool hasExistingBankDoc;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;

  const _BankEditForm({
    this.initialBankName,
    required this.initialAccountName,
    required this.initialAccountNumber,
    required this.initialBranchCode,
    required this.initialAccountType,
    required this.hasExistingBankDoc,
    required this.onSaved,
    this.onCancel,
  });

  @override
  ConsumerState<_BankEditForm> createState() => _BankEditFormState();
}

class _BankEditFormState extends ConsumerState<_BankEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _branchCodeCtrl;
  String? _bankName;
  late String _accountType;
  String? _pendingBankDocKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bankName = _banks.contains(widget.initialBankName)
        ? widget.initialBankName
        : null;
    _accountNameCtrl =
        TextEditingController(text: widget.initialAccountName);
    _accountNumberCtrl =
        TextEditingController(text: widget.initialAccountNumber);
    _branchCodeCtrl =
        TextEditingController(text: widget.initialBranchCode);
    _accountType = widget.initialAccountType;
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _branchCodeCtrl.dispose();
    super.dispose();
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
      _snack('Banking details saved', success: true);
      widget.onSaved();
    } catch (_) {
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

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Banking Details',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            if (widget.onCancel != null)
              TextButton(
                onPressed: widget.onCancel,
                child:
                    Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Shown to passengers when they book your trips.',
          style:
              GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _bankName,
                decoration: _dec('Bank *'),
                items: _banks
                    .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, style: GoogleFonts.dmSans())))
                    .toList(),
                onChanged: (v) => setState(() => _bankName = v),
                validator: (_) =>
                    _bankName == null ? 'Please select your bank' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNameCtrl,
                decoration: _dec('Account Holder Name *'),
                style: GoogleFonts.dmSans(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Account Number *'),
                style: GoogleFonts.dmSans(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchCodeCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Branch Code (optional)'),
                style: GoogleFonts.dmSans(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: _dec('Account Type *'),
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
              const SizedBox(height: 16),
              DocumentUploadTile(
                title: 'Bank Confirmation Letter',
                type: 'bank',
                uploaded: _pendingBankDocKey != null ||
                    widget.hasExistingBankDoc,
                onUploaded: (key) {
                  setState(() => _pendingBankDocKey = key);
                  _snack('Letter uploaded — tap Save to confirm',
                      success: true);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                      : const Text('Save Banking Details'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicles section
// ─────────────────────────────────────────────────────────────────────────────

class _VehiclesSection extends ConsumerWidget {
  final List<VehicleModel> vehicles;
  final WidgetRef ref;

  const _VehiclesSection({required this.vehicles, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vehicles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_outlined,
                    color: Colors.grey, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No vehicles registered yet.',
                      style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
                ),
              ],
            ),
          )
        else
          ...vehicles.map((v) => _VehicleCard(vehicle: v)),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text('Add Vehicle', style: GoogleFonts.dmSans()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
            );
            if (added == true) ref.invalidate(driverVehicleProvider);
          },
        ),
      ],
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon, label) = switch (vehicle.status) {
      'approved' => (Colors.green, Icons.check_circle_outline, 'Approved'),
      'rejected' => (Colors.red, Icons.cancel_outlined, 'Rejected'),
      _ => (Colors.orange, Icons.hourglass_empty_outlined, 'Under Review'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, size: 32, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.registrationNumber,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (vehicle.make != null || vehicle.model != null)
                  Text(
                    [
                      if (vehicle.year != null) vehicle.year.toString(),
                      if (vehicle.make != null) vehicle.make!,
                      if (vehicle.model != null) vehicle.model!,
                    ].join(' '),
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                Text('${vehicle.seats} seat${vehicle.seats == 1 ? '' : 's'}',
                    style: GoogleFonts.dmSans(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(label,
                      style: GoogleFonts.dmSans(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _confirmRetire(context, ref),
                child: Text(
                  'Retire',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRetire(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retire Vehicle'),
        content: Text(
          'Are you sure you want to retire ${vehicle.registrationNumber}? '
          'This vehicle will no longer be available for trips.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retire'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(driverApiProvider).retireVehicle(vehicle.id);
      ref.invalidate(driverVehicleProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.registrationNumber} retired',
                style: GoogleFonts.dmSans()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retire vehicle. Try again.')),
        );
      }
    }
  }
}
