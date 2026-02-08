import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DriverVerificationScreen extends ConsumerStatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  ConsumerState<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState
    extends ConsumerState<DriverVerificationScreen> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  // ---- NEW: BANKING DETAILS ----
  final accountNameCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final branchCodeCtrl = TextEditingController();
  String? bankName;
  String accountType = 'cheque';

  String? bankNameError;
  String? accountNameError;
  String? accountNumberError;

  final Map<String, String> uploadedDocs = {};
  bool submitting = false;

  bool get allDocsUploaded => uploadedDocs.length == 6;

  // bool get isFormValid =>
  //     firstNameCtrl.text.isNotEmpty &&
  //     lastNameCtrl.text.isNotEmpty &&
  //     addressCtrl.text.isNotEmpty &&
  //     allDocsUploaded;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    addressCtrl.dispose();

    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    branchCodeCtrl.dispose();

    super.dispose();
  }

  bool validateForm() {
    bool valid = true;

    setState(() {
      bankNameError = null;
      accountNameError = null;
      accountNumberError = null;

      if (bankName == null) {
        bankNameError = 'Please select your bank';
        valid = false;
      }

      if (accountNameCtrl.text.trim().isEmpty) {
        accountNameError = 'Account holder name is required';
        valid = false;
      }

      if (accountNumberCtrl.text.trim().isEmpty) {
        accountNumberError = 'Account number is required';
        valid = false;
      }
    });

    return valid &&
        firstNameCtrl.text.isNotEmpty &&
        lastNameCtrl.text.isNotEmpty &&
        addressCtrl.text.isNotEmpty &&
        uploadedDocs.length == 6;
  }

  // Future<void> _submit() async {
  //   if (!isFormValid || submitting) return;

  //   setState(() => submitting = true);

  //   try {
  //     final api = ref.read(driverApiProvider);

  //     await api.submitVerification(
  //       firstName: firstNameCtrl.text.trim(),
  //       lastName: lastNameCtrl.text.trim(),
  //       address: addressCtrl.text.trim(),
  //       documents: uploadedDocs,
  //     );

  //     // 🔄 Refresh authoritative user state
  //     await ref.read(authProvider.notifier).refreshMe();

  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Verification submitted successfully'),
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint('❌ Submit failed: $e');

  //     if (e is DioException) {
  //       debugPrint('STATUS: ${e.response?.statusCode}');
  //       debugPrint('DATA: ${e.response?.data}');
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to submit verification'),
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => submitting = false);
  //   }
  // }

  Future<void> _submit() async {
    if (submitting || !validateForm()) return;

    setState(() => submitting = true);

    try {
      final api = ref.read(driverApiProvider);

      // 1️⃣ FIRST: save banking details
      // await api.submitBankDetails(
      //   bankName: bankName!,
      //   accountName: accountNameCtrl.text.trim(),
      //   accountNumber: accountNumberCtrl.text.trim(),
      //   branchCode: branchCodeCtrl.text.trim(),
      //   accountType: accountType,
      // );

      // 2️⃣ THEN: submit verification + documents
      await api.submitVerification(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        bankName: bankName!,
        accountName: accountNameCtrl.text.trim(),
        accountNumber: accountNumberCtrl.text.trim(),
        branchCode: branchCodeCtrl.text.trim(),
        accountType: accountType,
        documents: uploadedDocs,
      );

      // Refresh user state
      await ref.read(authProvider.notifier).refreshMe();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification submitted successfully'),
        ),
      );
    } catch (e) {
      debugPrint('❌ Submit failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit verification'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = user.verificationStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatusCard(status: status),

              const SizedBox(height: 24),

              // 🟠 PENDING STATE
              if (status == DriverVerificationStatus.pending) ...[
                const Text(
                  'Your documents are being reviewed. This usually takes a short time.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).refreshMe();
                    },
                  ),
                ),
              ],

              // 🟡 FORM (NONE or REJECTED)
              if (status == DriverVerificationStatus.none ||
                  status == DriverVerificationStatus.rejected) ...[
                _SectionCard(
                  title: '👤 Personal Details',
                  child: Column(
                    children: [
                      TextField(
                        controller: firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Surname',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '🏦 Banking Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Bank dropdown ----
                      DropdownButtonFormField<String>(
                        value: bankName,
                        decoration: const InputDecoration(
                          labelText: 'Select your bank',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'FNB', child: Text('FNB')),
                          DropdownMenuItem(value: 'ABSA', child: Text('ABSA')),
                          DropdownMenuItem(
                              value: 'Standard Bank',
                              child: Text('Standard Bank')),
                          DropdownMenuItem(
                              value: 'Nedbank', child: Text('Nedbank')),
                          DropdownMenuItem(
                              value: 'Capitec', child: Text('Capitec')),
                          DropdownMenuItem(
                              value: 'TymeBank', child: Text('TymeBank')),
                          DropdownMenuItem(
                              value: 'Investec', child: Text('Investec')),
                        ],
                        onChanged: (value) {
                          setState(() => bankName = value);
                        },
                      ),
                      if (bankNameError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(bankNameError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),

                      const SizedBox(height: 12),

                      // ---- Account holder ----
                      TextField(
                        controller: accountNameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Account Holder Name'),
                      ),
                      if (accountNameError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(accountNameError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),

                      const SizedBox(height: 12),

                      // ---- Account number ----
                      TextField(
                        controller: accountNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Account Number'),
                      ),
                      if (accountNumberError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(accountNumberError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),

                      const SizedBox(height: 12),

                      // ---- Branch code ----
                      TextField(
                        controller: branchCodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Branch Code (optional)'),
                      ),

                      const SizedBox(height: 12),

                      // ---- Account type ----
                      DropdownButtonFormField<String>(
                        value: accountType,
                        decoration:
                            const InputDecoration(labelText: 'Account Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'cheque', child: Text('Cheque Account')),
                          DropdownMenuItem(
                              value: 'savings', child: Text('Savings Account')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => accountType = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '📎 Required Documents',
                  child: Column(
                    children: [
                      DocumentUploadTile(
                        title: 'ID Document',
                        type: 'id',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['id'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Driver License',
                        type: 'license',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['license'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Permit',
                        type: 'permit',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['permit'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'PrDP',
                        type: 'prdp',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['prdp'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Proof of Address',
                        type: 'proof',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['proof'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Proof of Banking Details',
                        type: 'bank',
                        onUploaded: (key) {
                          setState(() => uploadedDocs['bank'] = key);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (validateForm()) {
                              await _submit();
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit For Verification'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * UI Components
 * -------------------------------------------------------------------------- */

class _StatusCard extends StatelessWidget {
  final DriverVerificationStatus status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color color;
    late IconData icon;

    switch (status) {
      case DriverVerificationStatus.approved:
        text = 'You are a verified driver';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case DriverVerificationStatus.pending:
        text = 'Verification Pending';
        color = Colors.orange;
        icon = Icons.hourglass_top;
        break;
      case DriverVerificationStatus.rejected:
        text = 'Verification Rejected';
        color = Colors.red;
        icon = Icons.error;
        break;
      case DriverVerificationStatus.none:
        text = 'Verification Required';
        color = Colors.grey;
        icon = Icons.info;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
