import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController identifierCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  @override
  void dispose() {
    identifierCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const AppLogo(size: 72),
              const SizedBox(height: 12),
              const Text(
                'Welcome to digiQ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              const Spacer(),

              const SizedBox(height: 48),

              TextField(
                controller: identifierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          try {
                            await ref.read(authProvider.notifier).login(
                                  identifier: identifierCtrl.text.trim(),
                                  password: passwordCtrl.text.trim(),
                                );
                          } catch (_) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid username or password'),
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 12),

              // ➕ Signup link
              TextButton(
                onPressed: () {
                  debugPrint('🧪 SIGNUP BUTTON CLICKED');
                  context.go('/signup');
                },
                child: const Text('Create an account'),
              ),

              const SizedBox(height: 24),

              // ───── Divider ─────
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'DEV',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // 🛡️ Admin Login (DEV ONLY)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Login as Admin'),
                  onPressed: isLoading
                      ? null
                      : () async {
                          await ref.read(authProvider.notifier).logout();

                          await ref.read(authProvider.notifier).login(
                                identifier: 'test_admin',
                                password: 'dev',
                              );
                        },
                ),
              ),

              const Spacer(),

              if (isLoading) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
