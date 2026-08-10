import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../tracking/screens/order_tracking_screen.dart';

class BookInstallationScreen extends StatefulWidget {
  const BookInstallationScreen({super.key});

  @override
  State<BookInstallationScreen> createState() => _BookInstallationScreenState();
}

class _BookInstallationScreenState extends State<BookInstallationScreen> {
  String _installationType = 'New Installation';
  String _selectedTimeSlot = '02:00 PM';
  int _selectedDay = 14;

  final List<String> _timeSlots = ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Installation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Wizard Indicator ((1) Details -> (2) Schedule -> (3) Confirm)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepBubble('1', 'Details', true),
                  _buildStepLine(true),
                  _buildStepBubble('2', 'Schedule', true),
                  _buildStepLine(false),
                  _buildStepBubble('3', 'Confirm', false),
                ],
              ),

              const SizedBox(height: 28),

              // Installation Type Selection
              Text('Select Installation Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard('New Installation', Icons.videocam_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard('Existing Site Service', Icons.home_repair_service_outlined),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Calendar Date Picker Mock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
                  const Text('Aug 2024', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Sun', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Mon', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Tue', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Wed', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Thu', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Fri', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('Sat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isSelected = day == _selectedDay;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryRed : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Time Slot Selection
              Text('Select Time Slot', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _timeSlots.map((slot) {
                  final isSelected = slot == _selectedTimeSlot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: AppColors.surfaceWhite,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderTrackingScreen()),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, IconData icon) {
    final isSelected = title == _installationType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _installationType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRedLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryRed : AppColors.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(String step, String label, bool isActive) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primaryRed : AppColors.surfaceSecondary,
          child: Text(step, style: TextStyle(color: isActive ? Colors.white : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isActive ? AppColors.primaryRed : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? AppColors.primaryRed : AppColors.borderLight,
    );
  }
}
