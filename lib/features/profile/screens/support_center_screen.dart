import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Center'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Red Support Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.redGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "We're here to help!",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get expert support for your products',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('How can we help?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              _buildSupportTile(
                title: 'FAQs',
                subtitle: 'Find answers to common questions',
                icon: Icons.help_outline,
              ),
              _buildSupportTile(
                title: 'Raise a Ticket',
                subtitle: 'Submit your query or issue',
                icon: Icons.confirmation_number_outlined,
              ),
              _buildSupportTile(
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                icon: Icons.chat_bubble_outline,
              ),
              _buildSupportTile(
                title: 'Call Us',
                subtitle: '+91 98766 43210\nMon - Sat (9AM - 6PM)',
                icon: Icons.phone_outlined,
              ),
              _buildSupportTile(
                title: 'Email Us',
                subtitle: 'support@sktechnology.com\nWe reply within 24 hours',
                icon: Icons.email_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportTile({required String title, required String subtitle, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.2)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
      ),
    );
  }
}
