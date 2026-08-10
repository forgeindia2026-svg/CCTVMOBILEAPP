import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/login_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isLoading = true;
  List<OrderModel> _liveOrders = [];
  int _selectedIndex = 0;
  String _userDisplayName = 'Customer';
  String? _userEmail;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadLiveOrders();
  }

  Future<void> _loadLiveOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final name = await StorageService.getUserName();
      final email = await StorageService.getUserEmail();
      final phone = await StorageService.getUserPhone();
      final loggedIn = await StorageService.isLoggedIn();

      final activeEmail = email ?? (phone != null && phone.contains('@') ? phone : null);
      
      List<OrderModel> orders = [];
      if (activeEmail != null && activeEmail.isNotEmpty) {
        orders = await ApiService.fetchOrders(email: activeEmail);
      }

      if (mounted) {
        setState(() {
          _userDisplayName = name ?? 'Customer';
          _userEmail = activeEmail;
          _isLoggedIn = loggedIn;
          _liveOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOrders = _liveOrders.isNotEmpty;
    final currentOrder = hasOrders && _selectedIndex < _liveOrders.length
        ? _liveOrders[_selectedIndex]
        : null;

    final inProgressCount = _liveOrders.where((o) => o.isProcessing).length;
    final completedCount = _liveOrders.where((o) => o.isDelivered).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _isLoggedIn ? 'Welcome back, ${_userDisplayName.toLowerCase()}! 👋' : 'Order Tracking',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryRed),
            tooltip: 'Refresh Orders',
            onPressed: _loadLiveOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Website Customer Dashboard Summary Stat Cards Grid (Matching Image 1)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'TOTAL ORDERS',
                            count: '${_liveOrders.length}',
                            icon: Icons.shopping_bag_outlined,
                            iconBg: const Color(0xFFFFF1F2),
                            iconColor: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'IN PROGRESS',
                            count: '$inProgressCount',
                            icon: Icons.local_shipping_outlined,
                            iconBg: const Color(0xFFF0FDF4),
                            iconColor: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'COMPLETED',
                            count: '$completedCount',
                            icon: Icons.check_circle_outline,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'ACTIVE AMC',
                            count: _isLoggedIn ? '1' : '0',
                            icon: Icons.star_outline,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Logged Out / No Orders State
                    if (!_isLoggedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 54, color: AppColors.primaryRed),
                            const SizedBox(height: 12),
                            const Text(
                              'Log In to View Your Orders',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please log in to your account to view your live orders and technician tracking timeline.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                  _loadLiveOrders();
                                },
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('Log In / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!hasOrders)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_outlined, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No Recent Orders Found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail != null
                                  ? 'No active orders placed for $_userEmail yet.'
                                  : 'Place your first CCTV order to track live technician status here.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _loadLiveOrders,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh Dashboard'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Live Orders Selector Chips Bar
                      const Text(
                        'YOUR RECENT ORDERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _liveOrders.length,
                          itemBuilder: (context, index) {
                            final ord = _liveOrders[index];
                            final isSelected = index == _selectedIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(ord.orderNumber),
                                selected: isSelected,
                                selectedColor: AppColors.primaryRed,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primaryRed : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Order Header Card
                      if (currentOrder != null) _buildOrderHeaderCard(currentOrder),

                      const SizedBox(height: 20),

                      // Vertical Live Status Timeline
                      if (currentOrder != null) _buildLiveTimeline(currentOrder),

                      const SizedBox(height: 20),

                      // Ordered Items Summary Card
                      if (currentOrder != null && currentOrder.items.isNotEmpty)
                        _buildOrderedItemsSection(currentOrder),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderCard(OrderModel order) {
    final isDelivered = order.isDelivered;
    final isProcessing = order.isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? const Color(0xFFDCFCE7)
                      : isProcessing
                          ? AppColors.primaryRedLight
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusBadgeText,
                  style: TextStyle(
                    color: isDelivered
                        ? const Color(0xFF166534)
                        : isProcessing
                            ? AppColors.primaryRed
                            : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${order.customerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Address: ${order.shippingAddress}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Text(
                order.formattedTotal,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTimeline(OrderModel order) {
    final isDelivered = order.isDelivered;
    final isProcessing = order.isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRACKING TIMELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineStep(
            title: 'Order Placed',
            subtitle: 'Order confirmed & saved in backend database',
            isCompleted: true,
          ),
          _buildTimelineStep(
            title: 'Order Approved',
            subtitle: 'Payment verified & dispatched to technical team',
            isCompleted: true,
          ),
          _buildTimelineStep(
            title: 'Technician Assigned',
            subtitle: 'SK Tech certified team member assigned',
            isCompleted: isProcessing || isDelivered,
            isCurrent: isProcessing,
          ),
          _buildTimelineStep(
            title: 'Work in Progress / Transit',
            subtitle: 'Equipment dispatched & installation in progress',
            isCompleted: isDelivered,
            isCurrent: isProcessing,
          ),
          _buildTimelineStep(
            title: 'Completed & Delivered',
            subtitle: 'Final inspection handover & warranty activated',
            isCompleted: isDelivered,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedItemsSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ORDERED ITEMS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) {
          final imageUrl = item.fullImageUrl;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: AppColors.surfaceSecondary,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) {
                              return const Icon(Icons.videocam, color: AppColors.primaryRed, size: 28);
                            },
                          )
                        : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: isCompleted
                    ? (isCurrent ? AppColors.primaryRed : const Color(0xFF166534))
                    : AppColors.borderLight,
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isCurrent
                          ? Icons.access_time_filled
                          : Icons.circle,
                  size: 12,
                  color: isCompleted || isCurrent ? Colors.white : AppColors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF86EFAC) : AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCompleted || isCurrent ? const Color(0xFF0F172A) : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
