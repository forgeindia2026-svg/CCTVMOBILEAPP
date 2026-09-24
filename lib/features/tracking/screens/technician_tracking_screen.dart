import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TechnicianTrackingScreen extends StatefulWidget {
  final String? orderNumber;
  final String? serviceTitle;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final String? address;
  final String? technicianName;
  final String? technicianPhone;
  final String? technicianVehicle;
  final double? technicianRating;
  final String? status;

  const TechnicianTrackingScreen({
    super.key,
    this.orderNumber,
    this.serviceTitle,
    this.scheduledDate,
    this.scheduledTimeSlot,
    this.address,
    this.technicianName,
    this.technicianPhone,
    this.technicianVehicle,
    this.technicianRating,
    this.status,
  });

  @override
  State<TechnicianTrackingScreen> createState() => _TechnicianTrackingScreenState();
}

class _TechnicianTrackingScreenState extends State<TechnicianTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isAssigned {
    final name = widget.technicianName?.trim();
    return name != null && name.isNotEmpty && name.toLowerCase() != 'unassigned';
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned = _isAssigned;
    final orderId = widget.orderNumber ?? 'SK-ORD-64153';
    final service = widget.serviceTitle ?? 'CCTV Repair & Maintenance';
    final timeSlot = widget.scheduledTimeSlot ?? '02:00 PM';
    final date = widget.scheduledDate ?? 'Today';
    final addressText = widget.address ?? 'Service Address registered in profile';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Live Tracking'),
        elevation: 0,
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
                    color: const Color(0xFFEEF2F6),
                    child: Stack(
                      children: [
                        // Map Grid Lines & Waves Mock
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.15);
                              return Transform.scale(
                                scale: isAssigned ? 1.0 : scale,
                                child: Container(
                                  width: 250,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: (isAssigned ? AppColors.primaryRed : const Color(0xFF2563EB))
                                          .withValues(alpha: isAssigned ? 0.3 : 0.2 + (_pulseController.value * 0.2)),
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        if (isAssigned) ...[
                          // Technician Marker Pin (Only when assigned)
                          Positioned(
                            top: 100,
                            left: 90,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primaryRed,
                                  child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.technicianName ?? 'Technician',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Radar searching indicator when unassigned
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(Icons.radar, color: Color(0xFF2563EB), size: 32),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Allocating Nearest Specialist...',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Destination Marker Pin
                        Positioned(
                          bottom: 140,
                          right: 60,
                          child: const Column(
                            children: [
                              Icon(Icons.location_on, color: AppColors.primaryRed, size: 36),
                              Text('Your Location', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Header Floating Pill
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAssigned ? Icons.my_location : Icons.hourglass_top_rounded,
                            color: isAssigned ? AppColors.statusGreen : const Color(0xFFD97706),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAssigned ? 'Technician on the way' : 'Booking Confirmed • Assigning Technician',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAssigned ? AppColors.statusGreen : const Color(0xFFB45309),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Floating Card
                  Positioned(
                    bottom: 16,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAssigned) ...[
                            // Assigned Technician Profile
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryRedLight,
                                  child: Icon(Icons.person, color: AppColors.primaryRed, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(widget.technicianName ?? 'Technician', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text(' ${widget.technicianRating ?? 4.8}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Certified CCTV Technician', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    Text('Vehicle: ${widget.technicianVehicle ?? 'TN 30 AB 1234'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Call & Chat Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final phone = widget.technicianPhone ?? '+91 98765 12345';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Calling Technician $phone...')),
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
                          ] else ...[
                            // Unassigned Info Panel
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.pending_actions_outlined, color: Color(0xFFD97706), size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Assigning Technician',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              orderId,
                                              style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Slot: $date • $timeSlot',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primaryRed),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Service: $service',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      addressText,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Help / Support Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Calling Support Helpline (+91 98765 43210)...')),
                                      );
                                    },
                                    icon: const Icon(Icons.headset_mic_outlined, size: 18),
                                    label: const Text('Support'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    },
                                    icon: const Icon(Icons.home_outlined, size: 18),
                                    label: const Text('Home'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Step Progress Indicator Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStepBar('Request', true, isCurrent: false),
                              _buildStepBar('Assigned', isAssigned, isCurrent: !isAssigned),
                              _buildStepBar('On the way', isAssigned, isCurrent: isAssigned),
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
    Color barColor;
    if (isDone) {
      barColor = AppColors.primaryRed;
    } else if (isCurrent) {
      barColor = const Color(0xFFD97706);
    } else {
      barColor = AppColors.borderLight;
    }

    return Column(
      children: [
        Container(
          height: 4,
          width: 55,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isDone
                ? AppColors.primaryRed
                : (isCurrent ? const Color(0xFFD97706) : AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
