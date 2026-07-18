import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:digiQ/validators.dart';
import 'package:dio/dio.dart';
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
  // Step 0 = pick role, Step 1 = fill details
  int _step = 0;
  UserRole? _role;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _showSnack('Please enter your full name'); return; }
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) { _showSnack('Please enter your phone number'); return; }
    final email = _emailCtrl.text.trim();
    if (!isValidEmail(email)) { _showSnack('Please enter a valid email'); return; }
    final passwordError = validatePassword(_passwordCtrl.text);
    if (passwordError != null) { _showSnack(passwordError); return; }
    if (!_acceptedTerms || !_acceptedPrivacy) {
      _showSnack('You must accept the Terms and Privacy Policy');
      return;
    }
    try {
      await ref.read(authProvider.notifier).register(
            fullName: name,
            phoneNumber: phone,
            identifier: email,
            password: _passwordCtrl.text.trim(),
            role: _role!,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
          );
      if (!context.mounted) return;
      context.go('/verify-email');
    } catch (e) {
      if (!mounted) return;
      String message = 'Signup failed. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final serverMsg = data['message'];
          final msgStr = serverMsg is List
              ? serverMsg.first?.toString()
              : serverMsg?.toString();
          if (msgStr != null && msgStr.isNotEmpty) message = msgStr;
        }
      }
      _showSnack(message);
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
          // ── HEADER ───────────────────────────────────────────────────
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
                      icon: Icon(
                        _step == 0 ? Icons.arrow_back : Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        if (_step == 1) {
                          setState(() => _step = 0);
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    AppLogo(size: 30, dark: true),
                    const SizedBox(width: 10),
                    Text(
                      _step == 0 ? 'Create Account' : 'Your Details',
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

          // ── BODY ─────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _step == 0
                  ? _RoleStep(
                      key: const ValueKey('role'),
                      onSelect: (role) => setState(() {
                        _role = role;
                        _step = 1;
                      }),
                    )
                  : _DetailsStep(
                      key: const ValueKey('details'),
                      role: _role!,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      acceptedTerms: _acceptedTerms,
                      acceptedPrivacy: _acceptedPrivacy,
                      onTermsChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                      onPrivacyChanged: (v) =>
                          setState(() => _acceptedPrivacy = v ?? false),
                      isLoading: isLoading,
                      onSubmit: _submit,
                      isDark: isDark,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Step 1 — Role selection
 * -------------------------------------------------------------------------- */

class _RoleStep extends StatelessWidget {
  final ValueChanged<UserRole> onSelect;

  const _RoleStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What brings you here?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Choose your account type to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          _RoleCard(
            role: UserRole.passenger,
            icon: Icons.person_outlined,
            title: 'Passenger',
            subtitle: 'Book seats on verified driver trips',
            color: AppTheme.primary,
            onTap: () => onSelect(UserRole.passenger),
          ),
          const SizedBox(height: 14),
          _RoleCard(
            role: UserRole.driver,
            icon: Icons.drive_eta_outlined,
            title: 'Driver',
            subtitle: 'Offer trips and earn from your route',
            color: const Color(0xFF2E7D32),
            onTap: () => onSelect(UserRole.driver),
          ),
          const SizedBox(height: 14),
          _RoleCard(
            role: UserRole.fleetOwner,
            icon: Icons.directions_car_outlined,
            title: 'Fleet Owner',
            subtitle: 'Manage multiple drivers and vehicles',
            color: const Color(0xFF6A1B9A),
            onTap: () => onSelect(UserRole.fleetOwner),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Step 2 — Personal details form
 * -------------------------------------------------------------------------- */

class _DetailsStep extends StatelessWidget {
  final UserRole role;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onPrivacyChanged;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool isDark;

  const _DetailsStep({
    super.key,
    required this.role,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.isDark,
  });

  String get _roleLabel {
    switch (role) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.fleetOwner:
        return 'Fleet Owner';
      default:
        return 'Passenger';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Registering as: $_roleLabel',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Your details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Fill in the form to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: nameCtrl,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'e.g. 0821234567',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: passwordCtrl,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText:
                  '8+ chars · uppercase · lowercase · number · symbol',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: onToggleObscure,
              ),
            ),
          ),

          const SizedBox(height: 28),

          _LegalTile(
            value: acceptedTerms,
            onChanged: onTermsChanged,
            label: 'I agree to the ',
            linkLabel: 'Terms of Service',
            onLinkTap: () => context.push('/terms'),
          ),
          const SizedBox(height: 8),
          _LegalTile(
            value: acceptedPrivacy,
            onChanged: onPrivacyChanged,
            label: 'I agree to the ',
            linkLabel: 'Privacy Policy',
            onLinkTap: () => context.push('/privacy'),
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed:
                (!acceptedTerms || !acceptedPrivacy || isLoading)
                    ? null
                    : onSubmit,
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
