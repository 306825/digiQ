import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:digiQ/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (!isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }
    try {
      await ref.read(authProvider.notifier).login(
            identifier: email,
            password: _passwordCtrl.text.trim(),
          );
      if (!mounted) return;
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString();
      if (msg.contains('EMAIL_NOT_VERIFIED')) {
        context.go('/verify-email');
        return;
      }
      if (msg.contains('INVALID_CREDENTIALS')) {
        _showSnack('Invalid email or password');
      } else if (msg.contains('SERVER_OFFLINE')) {
        _showSnack('Server is currently offline');
      } else if (msg.contains('NETWORK_ERROR')) {
        _showSnack('Check your internet connection');
      } else {
        _showSnack('Something went wrong');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authProvider).status == AuthStatus.authenticating;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HERO ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0D2550), const Color(0xFF0D47A1)]
                      : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLogo(size: 68, dark: true),
                    const SizedBox(height: 16),
                    Text(
                      'digiQ',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your trusted ride-share platform',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── FORM CARD ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => isLoading ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sign in button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),

                  const SizedBox(height: 16),

                  // Sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Create one'),
                      ),
                    ],
                  ),

                  // // ── DEV SECTION ──────────────────────────────────────
                  // const SizedBox(height: 24),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //         child: Divider(
                  //             color: isDark
                  //                 ? AppTheme.darkDivider
                  //                 : AppTheme.divider)),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12),
                  //       child: Text(
                  //         'DEV',
                  //         style: theme.textTheme.bodySmall,
                  //       ),
                  //     ),
                  //     Expanded(
                  //         child: Divider(
                  //             color: isDark
                  //                 ? AppTheme.darkDivider
                  //                 : AppTheme.divider)),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),
                  // OutlinedButton.icon(
                  //   icon: const Icon(Icons.admin_panel_settings_outlined),
                  //   label: const Text('Login as Admin'),
                  //   onPressed: isLoading
                  //       ? null
                  //       : () async {
                  //           await ref.read(authProvider.notifier).logout();
                  //           await ref.read(authProvider.notifier).login(
                  //                 identifier: 'test_admin',
                  //                 password: 'dev',
                  //               );
                  //         },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
