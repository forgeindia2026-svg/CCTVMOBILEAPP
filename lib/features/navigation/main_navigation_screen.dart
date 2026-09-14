import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/language_provider.dart';
import '../cart/screens/cart_screen.dart';
import '../home/screens/home_screen.dart';
import '../products/screens/products_screen.dart';
import '../tracking/screens/order_tracking_screen.dart';
import '../installation/screens/installation_service_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _showCartToast = false;
  Timer? _cartToastTimer;
  int _prevItemCount = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const OrderTrackingScreen(),
    const InstallationServiceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _cartToastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option 4: Auto-hiding 4-Second Toast Bar with Manual Close (X)
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.itemCount != _prevItemCount) {
                final hadItems = _prevItemCount;
                _prevItemCount = cartProvider.itemCount;
                if (cartProvider.itemCount > hadItems && cartProvider.itemCount > 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _cartToastTimer?.cancel();
                      setState(() {
                        _showCartToast = true;
                      });
                      _cartToastTimer = Timer(const Duration(seconds: 4), () {
                        if (mounted) {
                          setState(() {
                            _showCartToast = false;
                          });
                        }
                      });
                    }
                  });
                } else if (cartProvider.itemCount == 0) {
                  _showCartToast = false;
                }
              }

              if (!_showCartToast || cartProvider.itemCount == 0) {
                return const SizedBox.shrink();
              }

              return AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _showCartToast ? Offset.zero : const Offset(0, 1),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'Item' : 'Items'} in Cart',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          Text(
                            '₹${cartProvider.totalAmount}',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          _cartToastTimer?.cancel();
                          setState(() => _showCartToast = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('View Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          _cartToastTimer?.cancel();
                          setState(() => _showCartToast = false);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<LanguageProvider>(
            builder: (context, lang, _) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.surfaceWhite,
                  selectedItemColor: AppColors.primaryRed,
                  unselectedItemColor: AppColors.textMuted,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home),
                      label: lang.tr('home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.inventory_2_outlined),
                      activeIcon: const Icon(Icons.inventory_2),
                      label: lang.tr('products'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.local_shipping_outlined),
                      activeIcon: const Icon(Icons.local_shipping),
                      label: lang.tr('orders'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.build_outlined),
                      activeIcon: const Icon(Icons.build),
                      label: lang.tr('service'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person),
                      label: lang.tr('profile'),
                    ),
                  ],
                ),
              );
            },
          ),
    ],
  ),
);
  }
}
