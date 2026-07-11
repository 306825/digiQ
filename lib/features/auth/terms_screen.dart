import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = theme.textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digi‑Q Terms & Conditions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ── Section 1 ──
            Text('1. Acceptance of Terms', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('By creating an account, riders and operators agree to these Terms & Conditions.', bodyStyle),
            _bullet('Continued use of Digi‑Q services constitutes ongoing acceptance.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 2 ──
            Text('2. Eligibility', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Riders must be 18 years or older.', bodyStyle),
            _bullet('Operators must hold valid licences and permits required under South African law.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 3 ──
            Text('3. Account Registration', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Users must provide accurate and complete information.', bodyStyle),
            _bullet('Digi‑Q reserves the right to suspend accounts for false or misleading information.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 4 ──
            Text('4. Personal Information & POPIA Compliance', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Digi‑Q processes personal information in accordance with the Protection of Personal Information Act (POPIA).', bodyStyle),
            _bullet('Information collected will be used only for service delivery, compliance, and security.', bodyStyle),
            _bullet('Users have the right to access, correct, or request deletion of their data.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 5 ──
            Text('5. Data Security', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Digi‑Q implements technical and organisational safeguards (Section 19 POPIA).', bodyStyle),
            _bullet('Breach notifications will be issued without delay to affected parties and the Information Regulator.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 6 ──
            Text('6. Confidentiality', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Operators must treat rider data as confidential and may not disclose it without consent.', bodyStyle),
            _bullet('Riders must respect operator information shared during transactions.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 7 ──
            Text('7. Service Use', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Riders agree to pay applicable fees.', bodyStyle),
            _bullet("Operators agree to deliver services in line with Digi‑Q's trade policy and industry standards.", bodyStyle),
            const SizedBox(height: 16),

            // ── Section 8 ──
            Text('8. Liability', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Digi‑Q is not liable for indirect losses but will take reasonable steps to ensure safe and secure transactions.', bodyStyle),
            const SizedBox(height: 16),

            // ── Section 9 ──
            Text('9. Termination', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Digi‑Q may suspend or terminate accounts for breach of these terms.', bodyStyle),
            _bullet('Upon termination, personal data will be returned or destroyed in line with POPIA Section 21.', bodyStyle),
            const SizedBox(height: 28),

            // ── Trade Policy ──
            const Divider(),
            const SizedBox(height: 16),
            Text('Digi‑Q Trade Policy', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ── Trade 1 ──
            Text('1. Fair Trade Principles', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('All transactions must be transparent, lawful, and non‑discriminatory.', bodyStyle),
            _bullet('Operators must disclose all fees and charges upfront.', bodyStyle),
            const SizedBox(height: 16),

            // ── Trade 2 ──
            Text('2. Rider Rights', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Riders have the right to clear pricing, safe service delivery, and protection of personal data.', bodyStyle),
            _bullet('Complaints must be addressed within 7 business days.', bodyStyle),
            const SizedBox(height: 16),

            // ── Trade 3 ──
            Text('3. Operator Obligations', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Operators must comply with South African transport and trade regulations.', bodyStyle),
            _bullet('Operators must maintain valid permits and insurance.', bodyStyle),
            _bullet('Operators must ensure data confidentiality when handling rider information.', bodyStyle),
            const SizedBox(height: 16),

            // ── Trade 4 ──
            Text('4. Payment & Settlement', style: headingStyle),
            const SizedBox(height: 8),
            _bullet("Payments are processed securely via Digi‑Q's platform.", bodyStyle),
            _bullet('Refunds and cancellations follow Consumer Protection Act (CPA) guidelines.', bodyStyle),
            const SizedBox(height: 16),

            // ── Trade 5 ──
            Text('5. Dispute Resolution', style: headingStyle),
            const SizedBox(height: 8),
            _bullet("Disputes will be handled through Digi‑Q's internal resolution process.", bodyStyle),
            _bullet('If unresolved, disputes may be escalated to the National Consumer Commission.', bodyStyle),
            const SizedBox(height: 16),

            // ── Trade 6 ──
            Text('6. Cross‑Border Data Transfers', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Any transfer of personal information outside South Africa will comply with Section 72 POPIA, ensuring equivalent protection standards.', bodyStyle),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
