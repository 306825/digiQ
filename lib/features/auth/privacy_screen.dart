import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = theme.textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strut Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Effective date: 1 September 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Text(
              'Strut ("we", "our", or "us") is committed to protecting your personal information in accordance with the Protection of Personal Information Act 4 of 2013 (POPIA) and all applicable South African privacy legislation. This policy explains what information we collect, how we use it, and your rights as a data subject.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            // 1
            Text('1. Information We Collect', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Full name, email address, and phone number at registration.', bodyStyle),
            _bullet('Vehicle details and operating licence information for drivers.', bodyStyle),
            _bullet('Pickup and drop-off location data when booking a trip.', bodyStyle),
            _bullet('Payment references and booking transaction records.', bodyStyle),
            _bullet('Device identifiers and app usage data for security and analytics.', bodyStyle),
            const SizedBox(height: 16),

            // 2
            Text('2. Purpose of Processing', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Creating and managing your Strut account.', bodyStyle),
            _bullet('Facilitating trip bookings and connecting riders with drivers.', bodyStyle),
            _bullet('Processing and recording payment references.', bodyStyle),
            _bullet('Sending transactional notifications (booking confirmations, trip updates).', bodyStyle),
            _bullet('Ensuring safety, security, and fraud prevention.', bodyStyle),
            _bullet('Complying with legal and regulatory obligations.', bodyStyle),
            const SizedBox(height: 16),

            // 3
            Text('3. Legal Basis for Processing', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Performance of a contract — processing necessary to provide the Strut service.', bodyStyle),
            _bullet('Legal obligation — compliance with POPIA, tax law, and transport regulations.', bodyStyle),
            _bullet('Legitimate interest — fraud prevention, platform security, and service improvement.', bodyStyle),
            _bullet('Consent — where you have given explicit consent (e.g. marketing communications).', bodyStyle),
            const SizedBox(height: 16),

            // 4
            Text('4. Sharing of Information', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Drivers receive the pickup address and first name of riders assigned to their trip — no additional personal data is shared.', bodyStyle),
            _bullet('Riders receive the driver\'s name and rating — no contact details are shared without consent.', bodyStyle),
            _bullet('We do not sell your personal information to third parties.', bodyStyle),
            _bullet('We may share information with service providers (cloud hosting, email delivery) under strict data-processing agreements.', bodyStyle),
            _bullet('We will disclose information to law enforcement or regulators where required by law.', bodyStyle),
            const SizedBox(height: 16),

            // 5
            Text('5. Data Retention', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Account information is retained for the lifetime of your account plus 5 years for legal compliance.', bodyStyle),
            _bullet('Trip and booking records are retained for 5 years in line with financial record-keeping requirements.', bodyStyle),
            _bullet('Deleted accounts have personal identifiers removed within 30 days; anonymised transaction records may be retained longer.', bodyStyle),
            const SizedBox(height: 16),

            // 6
            Text('6. Security', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Passwords are stored as one-way bcrypt hashes and never in plain text.', bodyStyle),
            _bullet('All data in transit is protected by TLS encryption.', bodyStyle),
            _bullet('Access to personal data is restricted to authorised personnel on a need-to-know basis.', bodyStyle),
            _bullet('In the event of a data breach we will notify affected users and the Information Regulator without undue delay, as required by POPIA Section 22.', bodyStyle),
            const SizedBox(height: 16),

            // 7
            Text('7. Cross-Border Transfers', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Our infrastructure is hosted in AWS data centres. Where data is processed outside South Africa, we ensure the recipient country provides equivalent protection as required by POPIA Section 72.', bodyStyle),
            const SizedBox(height: 16),

            // 8
            Text('8. Your Rights', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Access — request a copy of the personal information we hold about you.', bodyStyle),
            _bullet('Correction — request that inaccurate or incomplete information be corrected.', bodyStyle),
            _bullet('Deletion — request that your personal information be deleted (subject to legal retention requirements).', bodyStyle),
            _bullet('Objection — object to processing based on legitimate interest.', bodyStyle),
            _bullet('Withdraw consent — where processing is based on consent, you may withdraw it at any time.', bodyStyle),
            _bullet('Complaints — lodge a complaint with the Information Regulator of South Africa at inforeg.org.za.', bodyStyle),
            const SizedBox(height: 16),

            // 9
            Text('9. Children', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('Strut is not intended for use by persons under 18 years of age. We do not knowingly collect personal information from minors.', bodyStyle),
            const SizedBox(height: 16),

            // 10
            Text('10. Changes to This Policy', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('We may update this policy from time to time. Material changes will be notified in-app. Continued use of Strut after notification constitutes acceptance of the revised policy.', bodyStyle),
            const SizedBox(height: 16),

            // Contact
            Text('11. Contact Us', style: headingStyle),
            const SizedBox(height: 8),
            _bullet('For any privacy-related queries or to exercise your rights, contact us at support@struttech.co.za.', bodyStyle),
            _bullet('Information Officer: available on request via the support email above.', bodyStyle),
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
