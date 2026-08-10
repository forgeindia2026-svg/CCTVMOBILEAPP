import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/cart_provider.dart';
import '../../navigation/main_navigation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isSubmittingOrder = false;
  String _selectedServiceType = 'DELIVERY_INSTALLATION';

  void _showCheckoutDialog(CartProvider cartProvider) async {
    final name = await StorageService.getUserName() ?? 'Customer';
    final email = await StorageService.getUserEmail() ?? 'customer@example.com';
    final phone = await StorageService.getUserPhone() ?? '9876543210';

    final nameCtrl = TextEditingController(text: name);
    final emailCtrl = TextEditingController(text: email);
    final phoneCtrl = TextEditingController(text: phone);
    final addressCtrl = TextEditingController(text: '12, 3rd Cross Street, Anna Nagar, Chennai - 600040');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Checkout & Shipping Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: emailCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneCtrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Text('Delivery & Installation Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Service & Installation Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),

                    InkWell(
                      onTap: () {
                        setModalState(() {
                          _selectedServiceType = 'DELIVERY_INSTALLATION';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedServiceType == 'DELIVERY_INSTALLATION' ? AppColors.primaryRedLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedServiceType == 'DELIVERY_INSTALLATION' ? AppColors.primaryRed : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedServiceType == 'DELIVERY_INSTALLATION' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _selectedServiceType == 'DELIVERY_INSTALLATION' ? AppColors.primaryRed : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Product Delivery + Free Technician Installation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text('Backend automatically assigns certified technician', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          _selectedServiceType = 'ONLY_DELIVERY';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedServiceType == 'ONLY_DELIVERY' ? AppColors.primaryRedLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedServiceType == 'ONLY_DELIVERY' ? AppColors.primaryRed : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedServiceType == 'ONLY_DELIVERY' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _selectedServiceType == 'ONLY_DELIVERY' ? AppColors.primaryRed : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            const Text('Product Delivery Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Order Summary Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Payable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('₹${cartProvider.totalAmount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryRed)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: _isSubmittingOrder
                            ? null
                            : () async {
                                setModalState(() {
                                  _isSubmittingOrder = true;
                                });
                                await _submitOrderToBackend(
                                  customerName: nameCtrl.text.trim(),
                                  customerEmail: emailCtrl.text.trim(),
                                  customerPhone: phoneCtrl.text.trim(),
                                  shippingAddress: addressCtrl.text.trim(),
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                        child: _isSubmittingOrder
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Confirm & Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitOrderToBackend({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
  }) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final cartItemsForOrder = cartProvider.items.map((item) {
        return {
          'product': item['productId'],
          'quantity': item['qty'],
        };
      }).toList();

      final res = await ApiService.post('orders', {
        'products': cartItemsForOrder,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': '$shippingAddress [Service: ${_selectedServiceType.replaceAll('_', ' ')}]',
        'serviceType': _selectedServiceType,
        'totalAmount': cartProvider.totalAmount,
        'paymentStatus': 'PENDING',
        'orderStatus': 'PROCESSING',
      });

      if (res != null && res['success'] == true) {
        final orderId = res['data']['_id'];
        final orderNum = orderId.toString().substring(orderId.length - 6).toUpperCase();

        cartProvider.clearCart();

        // Save session user details so orders screen loads live data instantly
        await StorageService.saveSession(
          token: (await StorageService.getToken()) ?? 'session-token',
          email: customerEmail,
          phone: customerPhone,
          name: customerName,
        );

        if (mounted) {
          setState(() {
            _isSubmittingOrder = false;
          });

          // Show Order Success Modal
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Column(
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Icons.check_circle, color: Color(0xFF166534), size: 36),
                    ),
                    SizedBox(height: 12),
                    Text('Order Placed Successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                content: Text(
                  'Your Order ID is $orderNum.\n\nA SK Certified Technician has been automatically assigned to your order for delivery & installation!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to Orders Tab (index 2) to track live status!
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainNavigationScreen(initialIndex: 2),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Track Order & Technician'),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception(res?['message'] ?? 'Failed to place order.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final discountMRP = cartProvider.totalMRP - cartProvider.totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
              onPressed: () {
                cartProvider.clearCart();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Your Cart is Empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          const Text('Add CCTV cameras & security gear to get started', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Shop Products'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cartItems.length} items in Cart', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          // Cart Items List
                          ...cartItems.asMap().entries.map((entry) {
                            final item = entry.value;
                            return _buildCartCard(cartProvider, item);
                          }),

                          const SizedBox(height: 24),

                          // Price Details Section
                          const Text('Price Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildRow('Total MRP', '₹${cartProvider.totalMRP}'),
                                const SizedBox(height: 10),
                                _buildRow('Discount on MRP', '- ₹$discountMRP', isGreen: true),
                                const SizedBox(height: 10),
                                _buildRow('Delivery & Installation', 'FREE', isGreen: true),
                                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                        Text('(Inclusive of all taxes)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                      ],
                                    ),
                                    Text('₹${cartProvider.totalAmount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryRed)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Proceed to Checkout Button Bar
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => _showCheckoutDialog(cartProvider),
                    child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartCard(CartProvider cartProvider, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  image: item['image'] != null && item['image'].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item['image']),
                          fit: BoxFit.contain,
                        )
                      : null,
                ),
                child: item['image'] == null || item['image'].toString().isEmpty
                    ? const Icon(Icons.videocam, color: AppColors.primaryRed, size: 36)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(item['model'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('₹${item['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryRed)),
                        const SizedBox(width: 6),
                        Text('₹${item['original']}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRedLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item['discount'] as String, style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      if (item['qty'] > 1) {
                        cartProvider.updateQuantity(item['productId'], (item['qty'] as int) - 1);
                      }
                    },
                  ),
                  Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primaryRed),
                    onPressed: () {
                        cartProvider.updateQuantity(item['productId'], (item['qty'] as int) + 1);
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                onPressed: () {
                    cartProvider.removeFromCart(item['productId']);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isGreen ? const Color(0xFF166534) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
