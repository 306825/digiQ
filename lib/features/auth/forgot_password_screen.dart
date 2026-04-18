import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/shared/widgets/back_button_safe.dart';
import 'package:digiQ/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final api = ref.read(apiClientProvider);

      final url = '/auth/forgot-password';
      debugPrint('RESET REQUEST URL: ${api.dio.options.baseUrl}$url');

      await api.dio.post(url, data: {
        'identifier': email,
      });

      if (!mounted) return;

      // Better UX than instant redirect
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Check your email'),
          content: const Text(
            'If the account exists, a password reset link has been sent.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Password reset request failed: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reset email. Try again.'),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: const SafeBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Enter your email and we will send a reset link.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send reset link'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
