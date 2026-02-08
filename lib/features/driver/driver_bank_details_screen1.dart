import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class DriverBankDetailsScreen extends ConsumerStatefulWidget {
  const DriverBankDetailsScreen({super.key});

  @override
  ConsumerState<DriverBankDetailsScreen> createState() =>
      _DriverBankDetailsScreenState();
}

class _DriverBankDetailsScreenState
    extends ConsumerState<DriverBankDetailsScreen> {
  final accountNameCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final branchCodeCtrl = TextEditingController();
  String? bankName; // for dropdown

  String? bankNameError;
  String? accountNameError;
  String? accountNumberError;

  String accountType = 'cheque';
  bool submitting = false;

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

    return valid;
  }

  @override
  void dispose() {
    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    branchCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting || !validateForm()) return;

    setState(() => submitting = true);
    print("🔥 SENDING BANK DETAILS bankName: ${bankName.toString()}");
    print("🔥 SENDING BANK DETAILS account Name: ${accountNameCtrl.text}");
    print("🔥 SENDING BANK DETAILS account numeber: ${accountNumberCtrl.text}");
    print("🔥 SENDING BANK DETAILS branchcode: ${branchCodeCtrl.text}");
    print("🔥 SENDING BANK DETAILS account type: ${accountType.toString()}");
    try {
      final api = ref.read(driverApiProvider);

      await api.submitVerification(
        bankName: bankName!,
        accountName: accountNameCtrl.text.trim(),
        accountNumber: accountNumberCtrl.text.trim(),
        branchCode: branchCodeCtrl.text.trim(),
        accountType: accountType,
        firstName: '',
        lastName: '',
        address: '',
        documents: {},
      );

      if (!mounted) return;

      // Move to your existing document upload screen
      context.go('/driver/verify');
    } catch (e) {
      debugPrint('❌ Bank details submit failed: $e');

      if (e is DioException) {
        debugPrint('STATUS: ${e.response?.statusCode}');
        debugPrint('DATA: ${e.response?.data}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save banking details'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banking Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Enter your banking details before uploading documents.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: '🏦 Banking Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------- BANK NAME (DROPDOWN) --------
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
                        setState(() {
                          bankName = value; // 🔥 THIS LINE IS CRITICAL
                        });
                      },
                    ),
                    if (bankNameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          bankNameError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // -------- ACCOUNT HOLDER --------
                    TextField(
                      controller: accountNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                      ),
                    ),
                    if (accountNameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          accountNameError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // -------- ACCOUNT NUMBER --------
                    TextField(
                      controller: accountNumberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                      ),
                    ),
                    if (accountNumberError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          accountNumberError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // -------- BRANCH CODE (OPTIONAL) --------
                    TextField(
                      controller: branchCodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Branch Code (optional)',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // -------- ACCOUNT TYPE (UNCHANGED) --------
                    DropdownButtonFormField<String>(
                      value: accountType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque Account'),
                        ),
                        DropdownMenuItem(
                          value: 'savings',
                          child: Text('Savings Account'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => accountType = v);
                      },
                    ),
                  ],
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
