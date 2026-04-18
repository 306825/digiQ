import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/features/shared/widgets/back_button_safe.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final fullNameCtrl = TextEditingController();
  final identifierCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;

  UserRole role = UserRole.passenger;

  @override
  void dispose() {
    fullNameCtrl.dispose();
    identifierCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(size: 28),
            SizedBox(width: 8),
            Text('digiQ'),
          ],
        ),
        leading: const SafeBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: identifierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<UserRole>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Account type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.passenger,
                    child: Text('Passenger'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.driver,
                    child: Text('Driver'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => role = value);
                  }
                },
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: acceptedTerms,
                    onChanged: (value) {
                      setState(() => acceptedTerms = value ?? false);
                    },
                    title: GestureDetector(
                      onTap: () => context.push('/terms'),
                      child: const Text(
                        'I agree to the Terms of Service',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: acceptedPrivacy,
                    onChanged: (value) {
                      setState(() => acceptedPrivacy = value ?? false);
                    },
                    title: GestureDetector(
                      onTap: () => context.push('/privacy'),
                      child: const Text(
                        'I agree to the Privacy Policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = identifierCtrl.text.trim();

                          if (!isValidEmail(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a valid email')),
                            );
                            return;
                          }

                          if (!acceptedTerms || !acceptedPrivacy) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'You must accept Terms and Privacy Policy'),
                              ),
                            );
                            return;
                          }

                          try {
                            await ref.read(authProvider.notifier).register(
                                  fullName: fullNameCtrl.text.trim(),
                                  identifier: email,
                                  password: passwordCtrl.text.trim(),
                                  role: role,
                                  acceptedTerms: acceptedTerms,
                                  acceptedPrivacy: acceptedPrivacy,
                                );

                            if (!context.mounted) return;
                            context.go('/verify-email');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Signup failed: $e')),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
