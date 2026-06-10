import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:digiQ/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  UserRole _role = UserRole.passenger;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (!isValidEmail(email)) {
      _showSnack('Please enter a valid email');
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy) {
      _showSnack('You must accept the Terms and Privacy Policy');
      return;
    }
    try {
      await ref.read(authProvider.notifier).register(
            identifier: email,
            password: _passwordCtrl.text.trim(),
            role: _role,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
          );
      if (!context.mounted) return;
      context.go('/verify-email');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Signup failed: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.authenticating;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── COMPACT HEADER ───────────────────────────────────────────
          Container(
            width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                      onPressed: () => context.go('/login'),
                    ),
                    const SizedBox(width: 8),
                    AppLogo(size: 30, dark: true),
                    const SizedBox(width: 10),
                    Text(
                      'Create Account',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FORM ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your details', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the form to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

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

                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Account type
                  DropdownButtonFormField<UserRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'I am a…',
                      prefixIcon: Icon(Icons.person_outline),
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
                    onChanged: (v) {
                      if (v != null) _role = v;
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── LEGAL ──────────────────────────────────────────
                  _LegalTile(
                    value: _acceptedTerms,
                    onChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                    label: 'I agree to the ',
                    linkLabel: 'Terms of Service',
                    onLinkTap: () => context.push('/terms'),
                  ),
                  const SizedBox(height: 8),
                  _LegalTile(
                    value: _acceptedPrivacy,
                    onChanged: (v) =>
                        setState(() => _acceptedPrivacy = v ?? false),
                    label: 'I agree to the ',
                    linkLabel: 'Privacy Policy',
                    onLinkTap: () => context.push('/privacy'),
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed:
                        (!_acceptedTerms || !_acceptedPrivacy || isLoading)
                            ? null
                            : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String linkLabel;
  final VoidCallback onLinkTap;

  const _LegalTile({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkLabel,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
                children: [
                  TextSpan(text: label),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
