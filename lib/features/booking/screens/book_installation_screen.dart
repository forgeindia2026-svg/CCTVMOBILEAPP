import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../tracking/screens/order_tracking_screen.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart';

class BookInstallationScreen extends StatefulWidget {
  final String? initialServiceType;

  const BookInstallationScreen({
    super.key,
    this.initialServiceType,
  });

  @override
  State<BookInstallationScreen> createState() => _BookInstallationScreenState();
}

class _BookInstallationScreenState extends State<BookInstallationScreen> {
  int _currentStep = 2; // Step 2 is Scheduling, Step 3 is Confirm
  late String _installationType;
  String _selectedTimeSlot = '02:00 PM';
  int _selectedDay = 14;
  bool _isSubmitting = false;

  final List<String> _timeSlots = ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'];

  // Form keys and controllers for Step 3 Address & Problem Description
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _problemDescController = TextEditingController();

  // Image upload
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImageFiles = [];
  final List<String> _selectedImagesBase64 = [];

  @override
  void initState() {
    super.initState();
    _installationType = widget.initialServiceType ?? 'CCTV Installation';
    final now = DateTime.now();
    _selectedDay = (now.day <= 28) ? now.day : 14;
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final savedAddress = await StorageService.getUserAddress();
    if (savedAddress != null && savedAddress.isNotEmpty && mounted) {
      _addressController.text = savedAddress;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _problemDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImageFiles.add(file);
          _selectedImagesBase64.add(base64Str);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach image: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImageFiles.removeAt(index);
      _selectedImagesBase64.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload CCTV Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a photo or choose an existing picture of your CCTV setup or fault',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryRed),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture CCTV issue with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select image from device storage'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnlargedImage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImageFiles[index],
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    // 1. Form Validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Authentication Check
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to confirm your booking.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(returnToPrevious: true)),
      );
      if (success != true) return; // User canceled login
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 3. Retrieve user info from StorageService
      final email = await StorageService.getUserEmail() ?? 'customer@skvision.com';
      final name = await StorageService.getUserName() ?? 'Customer';
      final phone = await StorageService.getUserPhone() ?? '9876543210';

      final isServiceOrRepair = _installationType.toLowerCase().contains('service') || 
                                _installationType.toLowerCase().contains('repair') ||
                                _installationType.toLowerCase().contains('amc');

      final problemText = _problemDescController.text.trim();
      final fullDesc = problemText.isNotEmpty
          ? problemText
          : 'Service booking for $_installationType';

      final now = DateTime.now();
      final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';

      // 4. Construct Request Payload
      final requestBody = {
        'title': '$_installationType Service Request',
        'category': isServiceOrRepair ? 'Service' : 'Installation',
        'scheduledDate': formattedDate,
        'scheduledTimeSlot': _selectedTimeSlot,
        'orderCategory': 'Delivery & Installation',
        'customerQuery': problemText,
        'problemDescription': problemText,
        'description': fullDesc,
        'siteImages': _selectedImagesBase64,
        'images': _selectedImagesBase64,
        'customer': {
          'name': name,
          'phone': phone,
          'email': email,
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
        },
        'priority': (isServiceOrRepair || problemText.isNotEmpty) ? 'HIGH' : 'MEDIUM',
        'status': 'PENDING'
      };

      // 5. POST to backend API
      final res = await ApiService.post('jobs', requestBody);

      if (res != null && res['success'] == true) {
        if (!mounted) return;
        // 6. Show Success Dialogue
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Booking Success', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Your $_installationType has been successfully scheduled for $_selectedTimeSlot.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderTrackingScreen()),
                  );
                },
                child: const Text('Track Order', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        throw Exception(res?['message'] ?? 'Failed to register booking');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_installationType.contains('Repair') ? 'CCTV Repair & Service' : 'Book Installation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            if (_currentStep == 3) {
              setState(() {
                _currentStep = 2;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
                  _buildStepLine(_currentStep == 3),
                  _buildStepBubble('3', 'Confirm', _currentStep == 3),
                ],
              ),

              const SizedBox(height: 28),

              if (_currentStep == 2) ...[
                // Installation / Service Type Selection
                Text('Select Service Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildServiceTypeChip('CCTV Installation', Icons.videocam_outlined),
                      const SizedBox(width: 8),
                      _buildServiceTypeChip('CCTV Repair & Maintenance', Icons.build_outlined),
                      const SizedBox(width: 8),
                      _buildServiceTypeChip('AMC Service', Icons.verified_outlined),
                      const SizedBox(width: 8),
                      _buildServiceTypeChip('Site Survey', Icons.location_on_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Calendar Date Picker Mock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
                    const Text('This Month', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
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
                      setState(() {
                        _currentStep = 3;
                      });
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
              ] else ...[
                // STEP 3: CONFIRMATION, PROBLEM DETAILS, IMAGE UPLOAD & ADDRESS FORM
                Text('Confirm Installation Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                
                // Summary Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(Icons.settings_suggest_outlined, 'Service Type', _installationType),
                      const SizedBox(height: 10),
                      _buildSummaryRow(Icons.calendar_today_outlined, 'Scheduled Date', 'Day $_selectedDay'),
                      const SizedBox(height: 10),
                      _buildSummaryRow(Icons.access_time, 'Time Slot', _selectedTimeSlot),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Problem / Issue Description Field
                Row(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 20, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      'CCTV Problem / Issue Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explain what issue you are facing with your CCTV / DVR / system',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _problemDescController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Camera 2 display is black/flickering, DVR beeping, no video recording, wire damaged near main entrance...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Image Upload Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Photos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Text(
                      '${_selectedImageFiles.length}/5 Attached',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload photo of your camera, screen, DVR or faulty setup (helps technician diagnose)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Photo preview & add button row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Add Photo Button
                      if (_selectedImageFiles.length < 5)
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: 84,
                            height: 84,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryRed.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRed, size: 20),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add Photo',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Image Thumbnails
                      ..._selectedImageFiles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final file = entry.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _showEnlargedImage(idx),
                              child: Container(
                                width: 84,
                                height: 84,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderLight),
                                  image: DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _removeImage(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Text('Installation Address', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Address TextField
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address Line',
                          hintText: 'Flat / Street / Area',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // City TextField
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'e.g. Chennai',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Postal Code TextField
                      TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Postal Code',
                          hintText: 'e.g. 600001',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your postal code';
                          }
                          if (value.trim().length < 6) {
                            return 'Postal code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Confirm Booking Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBooking,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Confirm Booking'),
                              SizedBox(width: 8),
                              Icon(Icons.check, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryRed),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceTypeChip(String title, IconData icon) {
    final isSelected = title == _installationType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _installationType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRedLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryRed : AppColors.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
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
