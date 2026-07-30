import 'dart:io';

import 'package:digiQ/core/api/feedback_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _appVersion = '1.0.0-beta';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();

  String _category = 'idea';
  bool _submitting = false;
  bool _done = false;

  static const _categories = [
    ('bug',   '🐛', 'Something is broken'),
    ('idea',  '💡', 'Suggest an improvement'),
    ('other', '💬', 'General feedback'),
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await ref.read(feedbackApiProvider).submit(
            category: _category,
            message: _messageCtrl.text.trim(),
            appVersion: _appVersion,
            platform: Platform.isIOS ? 'iOS' : 'Android',
          );
      if (mounted) setState(() { _submitting = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send feedback. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SafeArea(
        child: _done ? _buildSuccess(cs) : _buildForm(theme, cs),
      ),
    );
  }

  Widget _buildSuccess(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Thank you!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Your feedback has been received.\nWe read every submission during the BETA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6), height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Help us improve Digi-Q',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Your feedback shapes the product. Tell us what\'s working, what\'s broken, or what you\'d love to see.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6), height: 1.45),
            ),

            const SizedBox(height: 28),

            // Category picker
            Text('Category',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: _categories.map((cat) {
                final (value, emoji, label) = cat;
                final selected = _category == value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      emoji: emoji,
                      label: label,
                      selected: selected,
                      onTap: () => setState(() => _category = value),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Message field
            Text('Message',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _messageCtrl,
              minLines: 5,
              maxLines: 12,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _hintForCategory(_category),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Please write at least a few words';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),
            Text(
              'Your name, role, app version, and platform are attached automatically.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45)),
            ),

            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? 'Sending…' : 'Send Feedback'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintForCategory(String cat) {
    switch (cat) {
      case 'bug':
        return 'Describe what happened and what you expected to happen…';
      case 'idea':
        return 'Describe the feature or improvement you have in mind…';
      default:
        return 'Share your thoughts…';
    }
  }
}

/* --------------------------------------------------------------------------
 * Category chip
 * -------------------------------------------------------------------------- */

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
