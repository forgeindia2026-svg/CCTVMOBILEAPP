import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../tracking/screens/technician_tracking_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  String _selectedIssue = 'Camera Not Working';
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _uploadedPhotos = ['photo1', 'photo2'];
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _issueTypes = [
    {'title': 'Camera Not Working', 'icon': Icons.no_photography},
    {'title': 'DVR/NVR Issue', 'icon': Icons.developer_board},
    {'title': 'Video Loss', 'icon': Icons.videocam_off},
    {'title': 'Installation Issue', 'icon': Icons.build},
    {'title': 'Cable Problem', 'icon': Icons.cable},
    {'title': 'Other Issue', 'icon': Icons.help_outline},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Service Request'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Issue Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Issue Type Grid (3x2)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _issueTypes.length,
                itemBuilder: (context, index) {
                  final issue = _issueTypes[index];
                  final isSelected = issue['title'] == _selectedIssue;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIssue = issue['title'] as String;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRedLight : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryRed : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            issue['icon'] as IconData,
                            color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            issue['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Upload Photos / Videos Section
              Text('Upload Photos / Videos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  ..._uploadedPhotos.map((photo) {
                    return Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: AppColors.primaryRed, size: 28),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add Photo Button (+)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _uploadedPhotos.add('photo_${_uploadedPhotos.length + 1}');
                      });
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryRed, style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add, color: AppColors.primaryRed, size: 28),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Describe Your Issue Field
              Text('Describe Your Issue', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Camera is not showing video from last 2 days...',
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest() {
    setState(() {
      _isSubmitting = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TechnicianTrackingScreen()),
      );
    });
  }
}
