import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../booking/screens/book_installation_screen.dart';

class InstallationServiceScreen extends StatelessWidget {
  const InstallationServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('installation_service')),
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
                          Text(
                            lang.tr('professional_installation'),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(lang.tr('done_by_experts'), style: const TextStyle(color: Colors.white70, fontSize: 13)),

                          const SizedBox(height: 16),

                          _buildCheckItem(lang.tr('expert_technicians')),
                          _buildCheckItem(lang.tr('neat_wiring')),
                          _buildCheckItem(lang.tr('satisfaction_guaranteed')),
                          _buildCheckItem(lang.tr('on_time_service')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Our Services List Section
                    Text(lang.tr('our_services'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    _buildServiceTile(
                      context,
                      title: lang.tr('cctv_installation_title'),
                      subtitle: '${lang.tr('starting_from')} ₹499',
                      icon: Icons.videocam_outlined,
                    ),
                    _buildServiceTile(
                      context,
                      title: lang.tr('cctv_repair_title'),
                      subtitle: '${lang.tr('starting_from')} ₹299',
                      icon: Icons.build_outlined,
                    ),
                    _buildServiceTile(
                      context,
                      title: lang.tr('amc_service_title'),
                      subtitle: '${lang.tr('starting_from')} ₹998/year',
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
                  child: Text(lang.tr('book_installation')),
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
              MaterialPageRoute(
                builder: (context) => BookInstallationScreen(initialServiceType: title),
              ),
            );
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryRed),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: isFree ? AppColors.statusGreen : AppColors.textSecondary,
              fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
