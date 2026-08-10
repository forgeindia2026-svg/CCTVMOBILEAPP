import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TechnicianTrackingScreen extends StatelessWidget {
  const TechnicianTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Live Tracking'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Canvas Container
            Expanded(
              child: Stack(
                children: [
                  // Map Background Graphic Mock
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE5E9F0),
                    child: Stack(
                      children: [
                        // Map Grid Lines Mock
                        Center(
                          child: Container(
                            width: 250,
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3), width: 3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        // Technician Marker Pin
                        const Positioned(
                          top: 100,
                          left: 90,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryRed,
                                child: Icon(Icons.navigation, color: Colors.white, size: 20),
                              ),
                              SizedBox(height: 2),
                              Text('Technician', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                            ],
                          ),
                        ),
                        // Destination Marker Pin
                        const Positioned(
                          bottom: 120,
                          right: 80,
                          child: Column(
                            children: [
                              Icon(Icons.location_on, color: AppColors.primaryRed, size: 36),
                              Text('Your Location', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Header Floating Pill ("Technician on the way")
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.my_location, color: AppColors.statusGreen, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Technician on the way',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusGreen, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Floating Technician Card
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1F000000), blurRadius: 15, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryRedLight,
                                child: Icon(Icons.person, color: AppColors.primaryRed, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Ramesh Kumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(width: 8),
                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                      Text(' 4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text('Technician', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text('Vehicle: TN 30 AB 1234', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Call & Chat Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Calling Technician Ramesh Kumar (+91 98765 12345)...')),
                                    );
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Opening Technician Chat...')),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Chat'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Step Progress Indicator Bar (Assigned -> On the way -> Working -> Completed)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStepBar('Assigned', true),
                              _buildStepBar('On the way', true, isCurrent: true),
                              _buildStepBar('Working', false),
                              _buildStepBar('Completed', false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBar(String label, bool isDone, {bool isCurrent = false}) {
    return Column(
      children: [
        Container(
          height: 4,
          width: 70,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primaryRed : AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.primaryRed : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
