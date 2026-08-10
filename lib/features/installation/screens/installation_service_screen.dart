import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../booking/screens/book_installation_screen.dart';

class InstallationServiceScreen extends StatelessWidget {
  const InstallationServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation Service'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner Card ("Professional Installation Done by Experts")
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professional\nInstallation',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          const Text('Done by Experts', style: TextStyle(color: Colors.white70, fontSize: 13)),

                          const SizedBox(height: 16),

                          _buildCheckItem('Trained & Certified Technicians'),
                          _buildCheckItem('Neat & Professional Wiring'),
                          _buildCheckItem('Satisfaction Guaranteed'),
                          _buildCheckItem('On-Time Service'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Our Services List Section
                    Text('Our Services', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    _buildServiceTile(
                      context,
                      title: 'CCTV Installation',
                      subtitle: 'Starting from ₹499',
                      icon: Icons.videocam_outlined,
                    ),
                    _buildServiceTile(
                      context,
                      title: 'CCTV Repair & Maintenance',
                      subtitle: 'Starting from ₹299',
                      icon: Icons.build_outlined,
                    ),
                    _buildServiceTile(
                      context,
                      title: 'AMC Service',
                      subtitle: 'Starting from ₹998/year',
                      icon: Icons.verified_outlined,
                    ),
                    _buildServiceTile(
                      context,
                      title: 'Site Survey',
                      subtitle: 'FREE',
                      icon: Icons.location_on_outlined,
                      isFree: true,
                    ),
                  ],
                ),
              ),
            ),

            // Book Installation Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookInstallationScreen()),
                    );
                  },
                  child: const Text('Book Installation'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.statusGreen, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, {required String title, required String subtitle, required IconData icon, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookInstallationScreen()),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isFree ? AppColors.statusGreen : AppColors.textSecondary,
            fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
      ),
    );
  }
}
