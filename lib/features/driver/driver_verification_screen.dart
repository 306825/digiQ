import 'dart:typed_data';

import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/core/api/driver_documents_api.dart';
import 'package:digiQ/core/api/user_api.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:digiQ/features/shared/widgets/address_autocomplete_field.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  DateTime? driversLicenseExpiry;
  DateTime? prdpExpiry;
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
  bool uploadingPhoto = false;
  String? profilePhotoUrl;

  bool get allDocsUploaded => uploadedDocs.length == 6;

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = Uint8List.fromList(await picked.readAsBytes());
    setState(() => uploadingPhoto = true);

    try {
      final userApi = ref.read(userApiProvider);
      final docsApi = ref.read(driverDocumentsApiProvider);

      final signed = await userApi.getAvatarUploadUrl(contentType: 'image/jpeg');
      await docsApi.uploadToS3(
        uploadUrl: signed['uploadUrl'],
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      final savedUrl = await userApi.saveAvatar(signed['publicUrl'] as String);
      setState(() => profilePhotoUrl = savedUrl);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate from the name collected at registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fullName = ref.read(authProvider).user?.fullName ?? '';
      if (fullName.isNotEmpty && firstNameCtrl.text.isEmpty) {
        final spaceIdx = fullName.indexOf(' ');
        if (spaceIdx != -1) {
          firstNameCtrl.text = fullName.substring(0, spaceIdx);
          lastNameCtrl.text = fullName.substring(spaceIdx + 1);
        } else {
          firstNameCtrl.text = fullName;
        }
      }
    });
  }

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

    // Reset errors
    setState(() {
      bankNameError = null;
      accountNameError = null;
      accountNumberError = null;
    });

    if (profilePhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photo')),
      );
      valid = false;
    }

    if (driversLicenseExpiry == null || prdpExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expiry dates')),
      );
      valid = false;
    }

    // ✅ Required fields
    if (firstNameCtrl.text.trim().isEmpty ||
        lastNameCtrl.text.trim().isEmpty ||
        addressCtrl.text.trim().isEmpty) {
      valid = false;
    }

    // ✅ Required documents ONLY
    final requiredDocs = ['id', 'license', 'prdp'];

    for (final doc in requiredDocs) {
      if (!uploadedDocs.containsKey(doc)) {
        valid = false;
      }
    }

    return valid;
  }

  Future<void> _pickDate({
    required Function(DateTime) onSelected,
  }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _submit() async {
    if (submitting || !validateForm()) return;

    setState(() => submitting = true);

    try {
      final api = ref.read(driverApiProvider);

      await api.submitVerification(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        driversLicenseExpiry: driversLicenseExpiry!.toIso8601String(),
        prdpExpiry: prdpExpiry!.toIso8601String(),
        bankName: bankName,
        accountName: accountNameCtrl.text.trim().isEmpty
            ? null
            : accountNameCtrl.text.trim(),
        accountNumber: accountNumberCtrl.text.trim().isEmpty
            ? null
            : accountNumberCtrl.text.trim(),
        branchCode: branchCodeCtrl.text.trim().isEmpty
            ? null
            : branchCodeCtrl.text.trim(),
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
                      // Profile photo
                      Center(
                        child: GestureDetector(
                          onTap: uploadingPhoto ? null : _pickAndUploadProfilePhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: profilePhotoUrl != null
                                    ? NetworkImage(profilePhotoUrl!)
                                    : null,
                                child: uploadingPhoto
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : profilePhotoUrl == null
                                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                                        : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profilePhotoUrl == null ? 'Tap to add profile photo *' : 'Tap to change photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: profilePhotoUrl == null ? Colors.red.shade400 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      AddressAutocompleteField(
                        controller: addressCtrl,
                        labelText: 'Residential Address',
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
                  title: '📎 Required Documents (Minimum)',
                  child: Column(
                    children: [
                      DocumentUploadTile(
                        title: 'ID Document',
                        type: 'id',
                        uploaded: uploadedDocs.containsKey('id'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['id'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Driver License',
                        type: 'license',
                        uploaded: uploadedDocs.containsKey('license'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['license'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Permit',
                        type: 'permit',
                        uploaded: uploadedDocs.containsKey('permit'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['permit'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'PrDP',
                        type: 'prdp',
                        uploaded: uploadedDocs.containsKey('prdp'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['prdp'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Proof of Address',
                        type: 'proof',
                        uploaded: uploadedDocs.containsKey('proof'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['proof'] = key);
                        },
                      ),
                      DocumentUploadTile(
                        title: 'Proof of Banking Details',
                        type: 'bank',
                        uploaded: uploadedDocs.containsKey('bank'),
                        onUploaded: (key) {
                          setState(() => uploadedDocs['bank'] = key);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '📅 Document Expiry',
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Driver License Expiry'),
                        subtitle: Text(
                          driversLicenseExpiry == null
                              ? 'Select date'
                              : driversLicenseExpiry!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () {
                          _pickDate(
                            onSelected: (date) {
                              setState(() => driversLicenseExpiry = date);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('PrDP Expiry'),
                        subtitle: Text(
                          prdpExpiry == null
                              ? 'Select date'
                              : prdpExpiry!.toLocal().toString().split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () {
                          _pickDate(
                            onSelected: (date) {
                              setState(() => prdpExpiry = date);
                            },
                          );
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
