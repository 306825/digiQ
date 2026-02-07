import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final fullNameCtrl = TextEditingController();
  final identifierCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

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
                  labelText: 'Email or Username',
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref.read(authProvider.notifier).register(
                                fullName: fullNameCtrl.text.trim(),
                                identifier: identifierCtrl.text.trim(),
                                password: passwordCtrl.text.trim(),
                                role: role,
                              );
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
