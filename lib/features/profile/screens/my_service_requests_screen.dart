import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/audio_helper.dart';
import '../../tracking/screens/technician_tracking_screen.dart';

class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  State<MyServiceRequestsScreen> createState() => _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  int _selectedFilter = 0;
  bool _isLoading = true;
  List<OrderModel> _serviceRequests = [];
  final List<String> _filters = ['All', 'Processing', 'Completed', 'Cancelled'];

  // Audio Playback State
  String? _currentlyPlayingId;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadServiceRequests();
  }

  @override
  void dispose() {
    AudioHelper.stopAudioData();
    super.dispose();
  }

  Future<void> _loadServiceRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = await StorageService.getUserEmail();
      final phone = await StorageService.getUserPhone();
      final activeEmail = email ?? (phone != null && phone.contains('@') ? phone : null);

      List<OrderModel> orders = [];
      if (activeEmail != null && activeEmail.isNotEmpty) {
        orders = await ApiService.fetchOrders(email: activeEmail);
      }

      final servicesOnly = orders.where((o) => o.isServiceRequest).toList();

      if (mounted) {
        setState(() {
          _serviceRequests = servicesOnly;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading service requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<OrderModel> get _filteredRequests {
    if (_selectedFilter == 0) return _serviceRequests;
    final filterName = _filters[_selectedFilter].toLowerCase();
    return _serviceRequests.where((o) => o.orderStatus.toLowerCase().contains(filterName)).toList();
  }

  Future<void> _togglePlayAudio(OrderModel req) async {
    final isSamePlaying = _currentlyPlayingId == req.id && _isAudioPlaying;

    if (isSamePlaying) {
      AudioHelper.stopAudioData();
      setState(() {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
      });
      return;
    }

    // Stop any previous audio first
    AudioHelper.stopAudioData();

    final audioToPlay = req.voiceNoteUrl.trim();

    if (audioToPlay.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No voice recording available for this request.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    AudioHelper.playAudioData(audioToPlay);

    setState(() {
      _currentlyPlayingId = req.id;
      _isAudioPlaying = true;
    });
  }

  void _showImageZoomDialog(BuildContext context, String imgStr, int index, int total) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImageWidget(imgStr, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Uploaded Photo $index of $total',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imgStr, {BoxFit fit = BoxFit.cover}) {
    if (imgStr.startsWith('data:image')) {
      try {
        final commaIdx = imgStr.indexOf(',');
        final b64 = commaIdx != -1 ? imgStr.substring(commaIdx + 1) : imgStr;
        final bytes = base64Decode(b64.trim());
        return Image.memory(bytes, fit: fit, errorBuilder: (c, e, s) => _errorIcon());
      } catch (_) {
        return _errorIcon();
      }
    } else if (imgStr.startsWith('http')) {
      return Image.network(imgStr, fit: fit, errorBuilder: (c, e, s) => _errorIcon());
    } else {
      return _errorIcon();
    }
  }

  Widget _errorIcon() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Service Requests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryRed),
            onPressed: _loadServiceRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Bar
            Container(
              color: Colors.white,
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Service Requests Found',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Booked installation & repair requests will show here.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: _loadServiceRequests,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh Requests'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final req = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildServiceCard(req),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(OrderModel req) {
    final isDelivered = req.isDelivered;
    final isThisAudioPlaying = _currentlyPlayingId == req.id && _isAudioPlaying;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.serviceTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request ID: ${req.orderNumber}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? const Color(0xFFDCFCE7) : AppColors.primaryRedLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.statusBadgeText,
                  style: TextStyle(
                    color: isDelivered ? const Color(0xFF166534) : AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Service Schedule & Details
          if (req.scheduledDate.isNotEmpty || req.scheduledTimeSlot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled: ${req.scheduledDate} ${req.scheduledTimeSlot.isNotEmpty ? "(${req.scheduledTimeSlot})" : ""}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),

          if (req.shippingAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.shippingAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),

          if (req.problemDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: ${req.problemDescription}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),

          // Playable Voice Note Recording Player (Strict real server audio)
          if (req.voiceNoteUrl.trim().isNotEmpty)
            InkWell(
              onTap: () => _togglePlayAudio(req),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isThisAudioPlaying ? AppColors.primaryRed : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: isThisAudioPlaying ? 1.0 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isThisAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      size: 22,
                      color: isThisAudioPlaying ? Colors.white : AppColors.primaryRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isThisAudioPlaying
                          ? 'Playing Voice Recording... (Tap to Pause)'
                          : 'Listen to Voice Recording ${req.voiceNoteDuration.isNotEmpty ? "(${req.voiceNoteDuration})" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isThisAudioPlaying ? Colors.white : AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Uploaded Site Photos Thumbnails
          if (req.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Uploaded Site Photos (${req.images.length}):',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 65,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: req.images.length,
                      itemBuilder: (context, imgIdx) {
                        final imgUrl = req.images[imgIdx];
                        return GestureDetector(
                          onTap: () => _showImageZoomDialog(context, imgUrl, imgIdx + 1, req.images.length),
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: _buildImageWidget(imgUrl),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.formattedTotal != '₹0' ? req.formattedTotal : 'Inspection / Free Quote',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TechnicianTrackingScreen(
                        orderNumber: req.orderNumber,
                        serviceTitle: req.serviceTitle,
                        scheduledDate: req.scheduledDate,
                        scheduledTimeSlot: req.scheduledTimeSlot,
                        address: req.shippingAddress,
                        status: req.orderStatus,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.two_wheeler, size: 16),
                label: const Text('Track Technician', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
