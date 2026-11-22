import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Help center screen
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Frequently Asked Questions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _FAQItem(
            question: 'How do I book an appointment?',
            answer: 'Go to Find Doctor from the home screen, select a doctor, and tap Book Appointment to choose your preferred date and time.',
          ),
          _FAQItem(
            question: 'What payment methods do you accept?',
            answer: 'We accept eSewa, Khalti, IME Pay, FonePay, and major credit/debit cards.',
          ),
          _FAQItem(
            question: 'How can I track my skin progress?',
            answer: 'Use the Photos tab to upload progress photos and the Journal tab to log daily symptoms and observations.',
          ),
          _FAQItem(
            question: 'Can I cancel my membership?',
            answer: 'Yes, you can cancel anytime from Profile > Membership. Your access continues until the end of your billing period.',
          ),
          _FAQItem(
            question: 'How do I view my prescriptions?',
            answer: 'Access all your prescriptions from the Prescriptions tab or Profile > Prescriptions.',
          ),
          _FAQItem(
            question: 'Is my data secure?',
            answer: 'Yes, we use industry-standard encryption and follow GDPR compliance to protect your health data.',
          ),

          const SizedBox(height: AppSpacing.xl),
          
          Text(
            'Contact Support',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: const Text('support@dermacare.com.np'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email app...')),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone Support'),
              subtitle: const Text('+977-1-5555555'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening phone app...')),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9 AM - 6 PM NPT'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live chat coming soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
