import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';
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
    String name = await StorageService.getUserName() ?? 'Customer';
    final email = await StorageService.getUserEmail() ?? '';
    String phone = await StorageService.getUserPhone() ?? '';

    // Fetch user address from live original MongoDB database
    String userAddress = '';
    if (email.isNotEmpty && email != 'customer@example.com') {
      try {
        final profileRes = await ApiService.get('auth/profile?email=${Uri.encodeComponent(email)}');
        if (profileRes != null && profileRes['success'] == true && profileRes['data'] != null) {
          final data = profileRes['data'];
          final dbAddr = data['address']?.toString().trim() ?? '';
          if (dbAddr.isNotEmpty) {
            userAddress = dbAddr;
          }
          // Sync profile to local storage cache
          await StorageService.saveSession(
            token: (await StorageService.getToken()) ?? 'session-token',
            email: email,
            name: data['name']?.toString() ?? name,
            phone: data['phone']?.toString() ?? phone,
            address: userAddress,
          );
        }
      } catch (e) {
        debugPrint('Could not fetch live profile address from DB: $e');
      }
    }

    // Fallback to local storage
    if (userAddress.isEmpty) {
      final cachedAddr = await StorageService.getUserAddress();
      if (cachedAddr != null && cachedAddr.trim().isNotEmpty) {
        userAddress = cachedAddr.trim();
      }
    }

    // Check LocationService saved delivery address
    if (userAddress.isEmpty) {
      final savedLoc = await LocationService.getSavedAddress();
      if (savedLoc.isNotEmpty && !savedLoc.contains('Shoolagiri / Hosur') && !savedLoc.contains('Hosur / Shoolagiri')) {
        userAddress = savedLoc;
      }
    }

    // Check saved addresses list
    if (userAddress.isEmpty) {
      final list = await LocationService.getSavedAddresses();
      if (list.isNotEmpty && (list.first['address'] ?? '').isNotEmpty) {
        userAddress = list.first['address']!;
        if ((name.isEmpty || name == 'Customer') && (list.first['name'] ?? '').isNotEmpty) {
          name = list.first['name']!;
        }
        if (phone.isEmpty && (list.first['phone'] ?? '').isNotEmpty) {
          phone = list.first['phone']!;
        }
      }
    }

    final nameCtrl = TextEditingController(text: name);
    final emailCtrl = TextEditingController(text: email.isNotEmpty ? email : 'customer@example.com');
    final phoneCtrl = TextEditingController(text: phone.isNotEmpty ? phone : '');
    final addressCtrl = TextEditingController(text: userAddress);

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
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '10-digit number',
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
                    // Delivery & Installation Address Card (Matching Image 1 & Image 2 design)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery & Installation Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        InkWell(
                          onTap: () async {
                            final chosen = await LocationService.showLocationPickerDetails(context, addressCtrl.text);
                            if (chosen != null) {
                              setModalState(() {
                                final newAddr = chosen['address'] ?? '';
                                final newName = chosen['name'] ?? '';
                                final newPhone = chosen['phone'] ?? '';

                                if (newAddr.isNotEmpty) {
                                  addressCtrl.text = newAddr;
                                }
                                if (newName.isNotEmpty && newName != 'Customer') {
                                  nameCtrl.text = newName;
                                }
                                if (newPhone.isNotEmpty) {
                                  phoneCtrl.text = newPhone;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location, size: 13, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  'Change / Pick',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Saved Address Card View (Matching Image 1 Card style)
                    InkWell(
                      onTap: () async {
                        final chosen = await LocationService.showLocationPickerDetails(context, addressCtrl.text);
                        if (chosen != null) {
                          setModalState(() {
                            final newAddr = chosen['address'] ?? '';
                            final newName = chosen['name'] ?? '';
                            final newPhone = chosen['phone'] ?? '';

                            if (newAddr.isNotEmpty) {
                              addressCtrl.text = newAddr;
                            }
                            if (newName.isNotEmpty && newName != 'Customer') {
                              nameCtrl.text = newName;
                            }
                            if (newPhone.isNotEmpty) {
                              phoneCtrl.text = newPhone;
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // Yellow Cream background as in Image 1
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF59E0B), // Golden yellow border
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selected Radio icon
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD97706),
                                  width: 6,
                                ),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Customer',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'WORK',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addressCtrl.text.isNotEmpty ? addressCtrl.text : 'Enter complete delivery address',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                      height: 1.35,
                                    ),
                                  ),
                                  if (phoneCtrl.text.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Contact: ${phoneCtrl.text}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Service & Installation Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedServiceType = 'DELIVERY_INSTALLATION';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _selectedServiceType == 'DELIVERY_INSTALLATION'
                                    ? AppColors.primaryRed.withValues(alpha: 0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedServiceType == 'DELIVERY_INSTALLATION'
                                      ? AppColors.primaryRed
                                      : const Color(0xFFE2E8F0),
                                  width: _selectedServiceType == 'DELIVERY_INSTALLATION' ? 1.5 : 1,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DELIVERY + INSTALLATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Verified technicians for expert setup.',
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedServiceType = 'ONLY_DELIVERY';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _selectedServiceType == 'ONLY_DELIVERY'
                                    ? AppColors.primaryRed.withValues(alpha: 0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedServiceType == 'ONLY_DELIVERY'
                                      ? AppColors.primaryRed
                                      : const Color(0xFFE2E8F0),
                                  width: _selectedServiceType == 'ONLY_DELIVERY' ? 1.5 : 1,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DELIVERY ONLY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Standard product shipping only.',
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 12),

                    // Payment Method Notice (Cash On Delivery / Site Payment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.payments_outlined, color: Color(0xFF166534), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment: Pay After Installation / Cash on Delivery',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
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
                                final cleanAddr = addressCtrl.text.trim();
                                if (cleanAddr.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your delivery & installation address'),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                if (phoneCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid 10-digit mobile number'),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() {
                                  _isSubmittingOrder = true;
                                });
                                final orderNum = await _submitOrderToBackend(
                                  customerName: nameCtrl.text.trim(),
                                  customerEmail: emailCtrl.text.trim(),
                                  customerPhone: phoneCtrl.text.trim(),
                                  shippingAddress: cleanAddr,
                                  setModalState: setModalState,
                                );
                                if (orderNum != null && context.mounted) {
                                  Navigator.pop(context); // Pop the modal sheet first!
                                  _showSuccessDialog(context, orderNum); // Show dialog on parent screen!
                                }
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

  void _showSuccessDialog(BuildContext context, String orderNum) {
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

  Future<String?> _submitOrderToBackend({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    required StateSetter setModalState,
  }) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final cartItemsForOrder = cartProvider.items.map((item) {
        return {
          'productId': item['productId'].toString(),
          'title': item['title'].toString(),
          'price': (item['price'] as num).toDouble(),
          'quantity': (item['qty'] as num).toInt(),
          'image': item['image'].toString(),
        };
      }).toList();

      final res = await ApiService.post('orders', {
        'items': cartItemsForOrder,
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

        // Save session user details and address so profile and orders load live data instantly
        await StorageService.saveSession(
          token: (await StorageService.getToken()) ?? 'session-token',
          email: customerEmail,
          phone: customerPhone,
          name: customerName,
          address: shippingAddress,
        );

        // Update live MongoDB database user profile with this address
        if (customerEmail.isNotEmpty) {
          try {
            await ApiService.put('auth/profile', {
              'email': customerEmail,
              'name': customerName,
              'phone': customerPhone,
              'address': shippingAddress,
            });
            debugPrint('Live MongoDB profile address updated: $shippingAddress');
          } catch (e) {
            debugPrint('Note: Failed to sync address to backend: $e');
          }
        }

        await LocationService.saveAddress(shippingAddress);
        await LocationService.addSavedAddress({
          'name': customerName,
          'phone': customerPhone,
          'address': shippingAddress,
          'type': 'Home',
          'isDefault': 'true',
        });

        if (mounted) {
          setModalState(() {
            _isSubmittingOrder = false;
          });
          setState(() {
            _isSubmittingOrder = false;
          });
        }
        return orderNum;
      } else {
        throw Exception(res?['message'] ?? 'Failed to place order.');
      }
    } catch (e) {
      if (mounted) {
        setModalState(() {
          _isSubmittingOrder = false;
        });
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
      return null;
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
                  image: item['image'] != null && item['image'].toString().isNotEmpty && !item['image'].toString().startsWith('local:')
                      ? DecorationImage(
                          image: NetworkImage(item['image']),
                          fit: BoxFit.contain,
                        )
                      : (item['image'] != null && item['image'].toString().startsWith('local:')
                          ? DecorationImage(
                              image: AssetImage('assets/images/${item['image'].toString().split(':')[1]}'),
                              fit: BoxFit.contain,
                            )
                          : null),
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
