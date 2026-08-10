import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../cart/screens/cart_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../../booking/screens/book_installation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _secondsLeft = 95489; // 01d : 02h : 31m : 29s
  Timer? _timer;
  Timer? _brandTimer;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  final ScrollController _brandScrollController = ScrollController();
  bool _isLoadingProducts = true;
  List<ProductModel> _liveProducts = [];

  bool _isLoadingCategories = true;
  List<Map<String, dynamic>> _dynamicCategories = [];

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'title': 'Next-Gen Security',
      'subtitle': 'Without Compromise',
      'desc': 'Smart HD CCTV systems with 2-year warranty & free installation.',
      'tag': 'BESTSELLER 2026',
      'gradient': [Color(0xFF0F172A), Color(0xFF1E293B)],
      'icon': Icons.videocam_rounded,
    },
    {
      'title': 'Hikvision 4K Ultra HD',
      'subtitle': 'ColorVu Night Vision',
      'desc': 'Full color 24/7 night vision with AI intruder detection.',
      'tag': 'HIKVISION SALE',
      'gradient': [Color(0xFF831843), Color(0xFFBE185D)],
      'icon': Icons.camera_indoor,
    },
    {
      'title': 'CP Plus 4CH/8CH DVR',
      'subtitle': 'Special Combo Deals',
      'desc': 'Complete CCTV package with Hard Disk, Cables & Adapter.',
      'tag': 'CP PLUS SPECIAL',
      'gradient': [Color(0xFF14532D), Color(0xFF15803D)],
      'icon': Icons.developer_board,
    },
  ];

  final List<Map<String, dynamic>> _budgetStores = [
    {'price': 'Under ₹999', 'tag': 'BUDGET ACCESSORIES', 'color': Color(0xFFDCFCE7), 'textColor': Color(0xFF166534)},
    {'price': 'Under ₹1,999', 'tag': 'SMART WIFI CAMERAS', 'color': Color(0xFFE0F2FE), 'textColor': Color(0xFF0369A1)},
    {'price': 'Under ₹4,999', 'tag': 'COMPLETE CCTV KITS', 'color': Color(0xFFFEF3C7), 'textColor': Color(0xFFB45309)},
  ];

  final List<String> _brandLogos = [
    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Honeywell_logo.svg/512px-Honeywell_logo.svg.png',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Hikvision_logo.svg/512px-Hikvision_logo.svg.png',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/TP-Link_logo_2016.svg/512px-TP-Link_logo_2016.svg.png',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/EZVIZ_logo.svg/512px-EZVIZ_logo.svg.png',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Dahua_Technology_logo.svg/512px-Dahua_Technology_logo.svg.png',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startBannerAutoScroll();
    _startBrandAutoScroll();
    _loadCategoriesFromBackend();
    _loadProductsFromBackend();
  }

  Future<void> _loadCategoriesFromBackend() async {
    try {
      final categories = await ApiService.fetchCategories(featuredOnly: true);
      // If none found from backend, fallback to default All Categories
      if (categories.isEmpty) {
        categories.insert(0, {
          'name': 'All Categories',
          'image': 'https://images.unsplash.com/photo-1496368077930-c1e31b4e5b44?auto=format&fit=crop&w=150&q=80',
        });
      } else {
        // Add "All Categories" as the first item
        categories.insert(0, {
          'name': 'All Categories',
          'image': 'https://images.unsplash.com/photo-1496368077930-c1e31b4e5b44?auto=format&fit=crop&w=150&q=80',
        });
      }
      if (mounted) {
        setState(() {
          _dynamicCategories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _startBrandAutoScroll() {
    _brandTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && _brandScrollController.hasClients) {
        double maxScroll = _brandScrollController.position.maxScrollExtent;
        double currentScroll = _brandScrollController.position.pixels;
        double delta = 1.5; // Scroll speed
        if (currentScroll >= maxScroll) {
          // If we somehow reach the end of the infinite list, jump back
          _brandScrollController.jumpTo(0);
        } else {
          _brandScrollController.jumpTo(currentScroll + delta);
        }
      }
    });
  }

  void _startBannerAutoScroll() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _bannerController.hasClients) {
        int nextIndex = (_currentBannerIndex + 1) % _heroBanners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentBannerIndex = nextIndex;
        });
      }
    });
  }

  Future<void> _loadProductsFromBackend() async {
    try {
      final products = await ApiService.fetchProducts();
      if (mounted) {
        setState(() {
          _liveProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home products: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brandTimer?.cancel();
    _bannerController.dispose();
    _brandScrollController.dispose();
    super.dispose();
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _formatTwoDigits(_secondsLeft ~/ 86400);
    final hours = _formatTwoDigits((_secondsLeft % 86400) ~/ 3600);
    final minutes = _formatTwoDigits((_secondsLeft % 3600) ~/ 60);
    final seconds = _formatTwoDigits(_secondsLeft % 60);

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unified Top Header Container Extending ALL THE WAY to device top edge (Status Bar completely filled with Red Color!)
            Container(
              padding: EdgeInsets.only(top: statusBarHeight + 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    Color(0xFF881337), // Deep Dark Red starting at Search Bar bottom
                    Color(0xFFB91C1C), // Rich Dark Red at Delivery Bar level
                    Color(0xFFDC2626), // Vibrant Red in upper header
                    Color(0xFFEF4444), // Rich Coral Red filling status bar top 100%!
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 1. Top Logo Header Bar (AppBar area)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/sklogo1.jpeg',
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'SK TECHNOLOGY',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                            ),
                            Text(
                              'CCTV SOLUTIONS',
                              style: TextStyle(color: Color(0xFFFECDD3), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined, size: 24, color: Colors.white),
                          onPressed: () {},
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CartScreen()),
                                );
                              },
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('2', style: TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Meesho / Flipkart Delivery Address Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Delivering to Anna Nagar, Chennai - 600040',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white, size: 18),
                      ],
                    ),
                  ),

                  // 3. Search Bar Container resting on Dark Red base
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search 27+ CCTV Cameras, DVR, NVR...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.primaryRed),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.mic, color: Color(0xFF64748B), size: 20),
                              SizedBox(width: 10),
                              Icon(Icons.qr_code_scanner, color: Color(0xFF64748B), size: 20),
                              SizedBox(width: 12),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Meesho Style Horizontal Category Badges Bar
            SizedBox(
              height: 105,
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _dynamicCategories.length,
                      itemBuilder: (context, index) {
                        final cat = _dynamicCategories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductsScreen(
                                  initialCategory: cat['name'] == 'All Categories' ? null : cat['name'] as String,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 66,
                                  height: 66,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: (cat['image'] as String).startsWith('local:') 
                                        ? Image.asset(
                                            'assets/images/${(cat['image'] as String).split(':')[1]}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                          )
                                        : Image.network(
                                            cat['image'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 5. Meesho "MAHA SAVINGS SALE" Countdown Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFFDE047), size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MAHA CCTV SAVINGS SALE ⚡',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text('Sale Ends in ', style: TextStyle(color: Colors.white, fontSize: 10)),
                            _buildSaleTimeChip(days, 'd'),
                            const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            _buildSaleTimeChip(hours, 'h'),
                            const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            _buildSaleTimeChip(minutes, 'm'),
                            const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            _buildSaleTimeChip(seconds, 's'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE047),
                      foregroundColor: const Color(0xFF991B1B),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                    child: const Text('UPTO 70% OFF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. Multi-Banner Sliding PageView Carousel (Flipkart Offer Carousel Style)
            SizedBox(
              height: 195,
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (idx) {
                  setState(() {
                    _currentBannerIndex = idx;
                  });
                },
                itemCount: _heroBanners.length,
                itemBuilder: (context, index) {
                  final item = _heroBanners[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item['gradient'] as List<Color>,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(item['tag'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                    Text(item['subtitle'] as String, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(item['desc'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(item['icon'] as IconData, size: 40, color: Colors.white),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProductsScreen()),
                                  );
                                },
                                child: const Text('Explore Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BookInstallationScreen()),
                                  );
                                },
                                child: const Text('Book Installation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_heroBanners.length, (idx) {
                final isSelected = idx == _currentBannerIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // 7. CCTV Budget Stores Row ("Under ₹999", "Under ₹1,999", "Under ₹4,999")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'CCTV BUDGET STORES',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _budgetStores.length,
                itemBuilder: (context, index) {
                  final store = _budgetStores[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: store['color'] as Color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: (store['textColor'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            store['price'] as String,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: store['textColor'] as Color),
                          ),
                          Text(
                            store['tag'] as String,
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: store['textColor'] as Color),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 8. Meesho Style "Liked By You ❤️" Section (Live MongoDB Products Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text('Liked by you ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))),
                      Text('❤️', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                    child: const Text('VIEW ALL >', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Live Products Cards Horizontal Stream
            _isLoadingProducts
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                  )
                : SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _liveProducts.length > 8 ? 8 : _liveProducts.length,
                      itemBuilder: (context, index) {
                        final prod = _liveProducts[index];
                        return _buildMeeshoStyleProductCard(context, prod);
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            // 9. Brand Spotlight Section ("Shop by Top Brands")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BRAND SPOTLIGHT ⭐', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  TextButton(
                    onPressed: () {},
                    child: const Text('ALL BRANDS', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                controller: _brandScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling since it auto-scrolls
                itemCount: 7,
                itemBuilder: (context, index) {
                  final i = index % 7;
                  Widget logoWidget;
                  if (i == 0) {
                    logoWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('HIK', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 18)),
                        const SizedBox(width: 4),
                        const Text('VISION', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 18)),
                      ],
                    );
                  } else if (i == 1) {
                    logoWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: const Text('a', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 4),
                        const Text('lhua', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 18)),
                      ],
                    );
                  } else if (i == 2) {
                    logoWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark, color: Color(0xFFDC2626), size: 24),
                        const SizedBox(width: 4),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('CP PLUS', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 16, height: 1)),
                            Text('enhancing vision', style: TextStyle(color: Color(0xFF475569), fontSize: 8)),
                          ],
                        ),
                      ],
                    );
                  } else if (i == 3) {
                    logoWidget = const Text('unv', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 24));
                  } else if (i == 4) {
                    logoWidget = const Text('EZVIZ', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900, fontSize: 20));
                  } else if (i == 5) {
                    logoWidget = const Text('tp-link', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w900, fontSize: 20));
                  } else {
                    logoWidget = Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shield, color: Color(0xFFF97316), size: 20),
                        SizedBox(width: 4),
                        Text('Imou', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w900, fontSize: 20)),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        width: 140, // Width for each logo container
                        alignment: Alignment.center,
                        child: logoWidget,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 10. Verified Customer Reviews & AMC Warranty Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF86EFAC), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('12,450+ Verified Installations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('⭐ 4.9 Rating • 2 Years Free Onsite Technician Warranty', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 11. Flipkart Style "Customer, still looking for these?" Green Card Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer, still looking for these?',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF166534)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _liveProducts.length > 5 ? 5 : _liveProducts.length,
                      itemBuilder: (context, index) {
                        final p = _liveProducts[index];
                        final imgUrl = p.fullImageUrl;
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: imgUrl.isNotEmpty
                                    ? (imgUrl.startsWith('local:')
                                        ? Image.asset(
                                            'assets/images/${imgUrl.split(':')[1]}',
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed),
                                          )
                                        : Image.network(
                                            imgUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed),
                                          ))
                                    : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 30),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.formattedPrice,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primaryRed),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 12. Full Live Grid of ALL 27 MongoDB Products ("Top Deals on Security Tech")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOP DEALS ON SECURITY TECH ⚡',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A), letterSpacing: 0.5),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                    child: const Text('SEE ALL', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _isLoadingProducts
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _liveProducts.length > 10 ? 10 : _liveProducts.length,
                    itemBuilder: (context, index) {
                      final prod = _liveProducts[index];
                      return _buildGridProductCard(context, prod);
                    },
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleTimeChip(String val, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$val$unit',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }

  Widget _buildMeeshoStyleProductCard(BuildContext context, ProductModel product) {
    final imageUrl = product.fullImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: product.title,
              price: product.formattedPrice,
              product: product,
            ),
          ),
        );
      },
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: imageUrl.isNotEmpty
                          ? (imageUrl.startsWith('local:')
                              ? Image.asset(
                                  'assets/images/${imageUrl.split(':')[1]}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 36),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 36),
                                ))
                          : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 36),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(14), bottomRight: Radius.circular(10)),
                    ),
                    child: const Text('SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${(product.price * 1.3).toInt()}',
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Free Delivery', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductCard(BuildContext context, ProductModel product) {
    final imageUrl = product.fullImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: product.title,
              price: product.formattedPrice,
              product: product,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: imageUrl.isNotEmpty
                          ? (imageUrl.startsWith('local:') 
                              ? Image.asset(
                                  'assets/images/${imageUrl.split(':')[1]}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                                ))
                          : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Top Deal', style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.brand.isNotEmpty ? product.brand : 'SK Tech Certified',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryRed),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_shopping_cart, color: AppColors.primaryRed, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
