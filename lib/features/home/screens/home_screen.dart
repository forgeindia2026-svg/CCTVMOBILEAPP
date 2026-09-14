import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/app_image.dart';
import 'package:provider/provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../../booking/screens/book_installation_screen.dart';
import '../../search/screens/barcode_scanner_screen.dart';
import '../../search/widgets/voice_search_bottom_sheet.dart';

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
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingProducts = true;
  List<ProductModel> _liveProducts = [];

  bool _isLoadingCategories = true;
  List<Map<String, dynamic>> _dynamicCategories = [];
  String _deliveryAddress = LocationService.defaultAddress;

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
    {'price': 'Under ₹999', 'tag': 'BUDGET ACCESSORIES', 'maxPrice': 999.0, 'color': Color(0xFFDCFCE7), 'textColor': Color(0xFF166534)},
    {'price': 'Under ₹1,999', 'tag': 'SMART WIFI CAMERAS', 'maxPrice': 1999.0, 'color': Color(0xFFE0F2FE), 'textColor': Color(0xFF0369A1)},
    {'price': 'Under ₹4,999', 'tag': 'COMPLETE CCTV KITS', 'maxPrice': 4999.0, 'color': Color(0xFFFEF3C7), 'textColor': Color(0xFFB45309)},
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
    _loadLocation();
    _loadCategoriesFromBackend();
    _loadProductsFromBackend();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brandTimer?.cancel();
    _bannerController.dispose();
    _brandScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSearch(String query) {
    if (query.trim().isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductsScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(initialSearchQuery: query.trim()),
      ),
    );
  }

  Future<void> _handleVoiceSearch() async {
    final result = await VoiceSearchBottomSheet.show(context);
    if (result != null && result.trim().isNotEmpty && mounted) {
      _searchController.text = result.trim();
      _navigateToSearch(result.trim());
    }
  }

  Future<void> _handleBarcodeScan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null && result.trim().isNotEmpty && mounted) {
      _searchController.text = result.trim();
      _navigateToSearch(result.trim());
    }
  }

  void _loadLocation() async {
    final saved = await LocationService.getSavedAddress();
    if (mounted) {
      setState(() {
        _deliveryAddress = saved;
      });
    }
    // Auto-detect live location if initial/default
    if (saved == LocationService.defaultAddress) {
      final live = await LocationService.fetchLiveLocation();
      if (mounted) {
        setState(() {
          _deliveryAddress = live;
        });
      }
    }
  }

  Future<void> _loadCategoriesFromBackend() async {
    try {
      final categories = await ApiService.fetchCategories();
      // Add "All Categories" as the first item
      categories.insert(0, {
        'name': 'All Categories',
        'image': 'https://sk-cctv-website.s3.ap-south-1.amazonaws.com/products/cctv-hd-camera.png',
      });
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

  final List<Map<String, dynamic>> _fallbackHomeProducts = const [];

  Future<void> _loadProductsFromBackend() async {
    try {
      final products = await ApiService.fetchProducts();
      if (mounted) {
        setState(() {
          _liveProducts = products.isNotEmpty
              ? products
              : _fallbackHomeProducts.map((e) => ProductModel.fromJson(e)).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home products: $e');
      if (mounted) {
        setState(() {
          _liveProducts = _fallbackHomeProducts.map((e) => ProductModel.fromJson(e)).toList();
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



  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final days = _formatTwoDigits(_secondsLeft ~/ 86400);
    final hours = _formatTwoDigits((_secondsLeft % 86400) ~/ 3600);
    final minutes = _formatTwoDigits((_secondsLeft % 3600) ~/ 60);
    final seconds = _formatTwoDigits(_secondsLeft % 60);

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFEF4444),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified Top Header Container
                Container(
                  padding: const EdgeInsets.only(top: 4),
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
                        Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            final count = cart.itemCount;
                            return IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CartScreen()),
                                );
                              },
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.white),
                                  if (count > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 2. Meesho / Flipkart Delivery Address Strip with Live GPS & Location Picker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: InkWell(
                      onTap: () async {
                        final selected = await LocationService.showLocationPicker(context, _deliveryAddress);
                        if (selected != null && mounted) {
                          setState(() {
                            _deliveryAddress = selected;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Delivery address set to: $selected',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF15803D),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _deliveryAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
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
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => _navigateToSearch(val),
                        decoration: InputDecoration(
                          hintText: lang.tr('search_hint'),
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: GestureDetector(
                            onTap: () => _navigateToSearch(_searchController.text),
                            child: const Icon(Icons.search, color: AppColors.primaryRed),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _handleVoiceSearch,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.mic, color: AppColors.primaryRed, size: 20),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _handleBarcodeScan,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.qr_code_scanner, color: Color(0xFF64748B), size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                        final catDisplayName = cat['name'] == 'All Categories' ? lang.tr('all_categories') : cat['name'] as String;
                        return RepaintBoundary(
                          key: ValueKey('cat_${cat['name']}'),
                          child: GestureDetector(
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
                                      child: AppImage(
                                        imageUrl: cat['image'] as String?,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    catDisplayName,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 5. Meesho "MAHA SAVINGS SALE" Countdown Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title & UPTO 70% OFF Badge
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Color(0xFFFDE047), size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${lang.tr('mega_sale')} ⚡',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProductsScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE047),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            lang.tr('upto_70_off'),
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: Clean Full-Width Countdown Timer Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFFFDE047), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${lang.tr('sale_ends_in')} ',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 3),
                          _buildSaleTimeChip(days, 'd'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5),
                            child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          _buildSaleTimeChip(hours, 'h'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5),
                            child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          _buildSaleTimeChip(minutes, 'm'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1.5),
                            child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          _buildSaleTimeChip(seconds, 's'),
                        ],
                      ),
                    ),
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
                                child: Text(lang.tr('explore_now'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                                child: Text(lang.tr('book_installation'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
              child: Text(
                lang.tr('budget_stores'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: 0.5),
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
                        MaterialPageRoute(
                          builder: (context) => ProductsScreen(
                            maxPrice: store['maxPrice'] as double?,
                          ),
                        ),
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

            // 8. Meesho Style "You May Also Like ✨" Section (Live MongoDB Products Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text('You May Also Like ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))),
                      Text('✨', style: TextStyle(fontSize: 16)),
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

            // === NEW 1: SHOP BY PROPERTY TYPE (Security Solutions Grid) ===
            _buildShopByPropertyType(context),

            const SizedBox(height: 24),

            // === NEW 2: COMPLETE CCTV SETUP COMBO KITS (Best Seller Packages) ===
            _buildCctvComboKitsSection(context),

            const SizedBox(height: 24),

            // === NEW 3: BOOK FREE CCTV SITE INSPECTION BANNER ===
            _buildFreeSiteSurveyBanner(context),

            const SizedBox(height: 24),

            // 9. Brand Spotlight Section ("Shop by Top Brands")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BRAND SPOTLIGHT ⭐', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
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
                physics: const NeverScrollableScrollPhysics(),
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
                        width: 140,
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

            // === NEW 4: COLORVU 24/7 NIGHT VISION SPOTLIGHT ===
            _buildColorVuSpotlightCard(context),

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
                                child: AppImage(
                                  imageUrl: p.image,
                                  fit: BoxFit.contain,
                                ),
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
                      childAspectRatio: 0.54,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _liveProducts.length,
                    itemBuilder: (context, index) {
                      final prod = _liveProducts[index];
                      return _buildGridProductCard(context, prod);
                    },
                  ),

            const SizedBox(height: 24),

            // === NEW 5: SK SECURITY TRUST & WARRANTY BADGES STRIP ===
            _buildTrustAndGuaranteeStrip(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
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
    final lang = Provider.of<LanguageProvider>(context);
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
                      child: AppImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                      ),
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
                  Text(lang.tr('free_delivery'), style: const TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductCard(BuildContext context, ProductModel product) {
    final lang = Provider.of<LanguageProvider>(context);
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. CCTV Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFFBFBFC),
                      padding: const EdgeInsets.all(6),
                      child: Center(
                        child: AppImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // Top Deal Badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Top Deal',
                      style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Flipkart / Amazon Style Details Section (Filled, compact, zero whitespace)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Name
                  Text(
                    product.brand.isNotEmpty ? product.brand.toUpperCase() : 'SK TECH CERTIFIED',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 2-Line Product Title
                  SizedBox(
                    height: 30,
                    child: Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Rating Star Pill + SK Assured Badge (Flipkart Style)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D), // Flipkart green
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${product.rating > 0 ? product.rating : 4.8}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewsCount > 0 ? product.reviewsCount : 128})',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'SK Assured',
                          style: TextStyle(
                            fontSize: 8,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price Row with Strikethrough & Green Discount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (product.formattedOriginalPrice.isNotEmpty) ...[
                        Text(
                          product.formattedOriginalPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          product.discountTag.isNotEmpty ? product.discountTag : '25% OFF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Free Delivery Row
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFF16A34A), size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lang.tr('free_delivery'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF16A34A), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Big Add to Cart / Quantity Selector Button (Full width at bottom)
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final qty = cartProvider.getItemQuantity(product.id);
                      if (qty == 0) {
                        return InkWell(
                          onTap: () {
                            cartProvider.addToCart(product);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 32,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4), width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_shopping_cart, color: AppColors.primaryRed, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  lang.tr('add_to_cart').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryRed,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => cartProvider.decrementQuantity(product.id),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                child: Icon(Icons.remove, color: Colors.white, size: 16),
                              ),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            InkWell(
                              onTap: () => cartProvider.addToCart(product),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                child: Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === 1. SHOP BY PROPERTY TYPE (100% Live Database Dynamic Pricing & Photos) ===
  Widget _buildShopByPropertyType(BuildContext context) {
    // Helper to find matching product and minimum price from live MongoDB catalog
    Map<String, dynamic> resolvePropertyData(String query, String fallbackAsset, String title, String subtitle, String discount, List<Color> gradient, Color accent) {
      final q = query.toLowerCase();
      final matches = _liveProducts.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q)
      ).toList();

      ProductModel? leadProduct;
      int minPrice = 0;
      if (matches.isNotEmpty) {
        matches.sort((a, b) => a.price.compareTo(b.price));
        leadProduct = matches.first;
        minPrice = leadProduct.price.toInt();
      }

      String priceText = minPrice > 0 ? 'From ₹$minPrice' : 'Explore Range';
      String? liveImageUrl = leadProduct?.image;

      return {
        'title': title,
        'subtitle': subtitle,
        'deal': priceText,
        'discount': leadProduct != null && leadProduct.discountTag.isNotEmpty ? leadProduct.discountTag : discount,
        'liveImageUrl': liveImageUrl,
        'assetFallback': fallbackAsset,
        'bgGradient': gradient,
        'accentColor': accent,
        'query': query,
      };
    }

    final List<Map<String, dynamic>> properties = [
      resolvePropertyData(
        'Wi-Fi',
        'assets/images/wifi_camera.png',
        'Home & Villa',
        '360° WiFi PTZ Cameras',
        '22% OFF',
        [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        const Color(0xFF0284C7),
      ),
      resolvePropertyData(
        'Dome',
        'assets/images/ip_camera.png',
        'Shops & Retail',
        'Cash Counter Dome Cams',
        '29% OFF',
        [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)],
        const Color(0xFFE11D48),
      ),
      resolvePropertyData(
        'Bullet',
        'assets/images/ip_camera_test.png',
        'Factory & Warehouse',
        '4K ColorVu Long Range',
        '54% OFF',
        [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        const Color(0xFFD97706),
      ),
      resolvePropertyData(
        'DVR',
        'assets/images/dvr.png',
        'Offices & Buildings',
        'NVR & Multi-Channel Kits',
        '51% OFF',
        [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
        const Color(0xFF7C3AED),
      ),
    ];

    final lang = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.tr('security_solutions_for_you')} 🏢',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(lang.tr('customized_packages'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: properties.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.69,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (ctx, i) {
              final item = properties[i];
              final liveImg = item['liveImageUrl'] as String?;
              final assetFallback = item['assetFallback'] as String;
              final accentColor = item['accentColor'] as Color;
              final bgGradient = item['bgGradient'] as List<Color>;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => ProductsScreen(initialSearchQuery: item['query'] as String)),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Image Box with Rich Vibrant Pastel Background
                      Container(
                        height: 128,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: bgGradient,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    bgGradient.first,
                                    BlendMode.multiply,
                                  ),
                                  child: AppImage(
                                    imageUrl: assetFallback.isNotEmpty ? assetFallback : (liveImg ?? ''),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // Floating Discount Badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item['discount'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Info Details
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (item['deal'] as String).replaceAll('From ', '${lang.tr('starting_from')} '),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: accentColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_forward_ios, size: 9, color: accentColor),
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
            },
          ),
        ],
      ),
    );
  }

  // === 2. COMPLETE CCTV SETUP COMBO KITS (Admin Managed Prices from Database) ===
  Widget _buildCctvComboKitsSection(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    // Find kit/combo products from live DB or fallback to top combo setups
    final List<ProductModel> kitMatches = _liveProducts.where((p) =>
      p.category.toLowerCase().contains('kit') ||
      p.category.toLowerCase().contains('combo') ||
      p.title.toLowerCase().contains('kit') ||
      p.title.toLowerCase().contains('set') ||
      p.title.toLowerCase().contains('dvr')
    ).toList();

    // Map into rich kit cards using real DB prices
    final List<Map<String, dynamic>> comboKits = [];

    if (kitMatches.isNotEmpty) {
      for (int i = 0; i < (kitMatches.length > 4 ? 4 : kitMatches.length); i++) {
        final p = kitMatches[i];
        comboKits.add({
          'product': p,
          'title': p.title,
          'includes': p.description.isNotEmpty ? p.description : 'Complete Security Bundle with Free Installation',
          'price': p.formattedPrice,
          'originalPrice': p.formattedOriginalPrice,
          'discount': p.discountTag.isNotEmpty ? p.discountTag : 'SPECIAL PRICE',
          'warranty': p.displayWarranty,
          'badge': i == 0 ? '🔥 Top Seller' : (i == 1 ? '⭐ Commercial Pro' : '⚡ Complete Kit'),
          'gradient': i % 2 == 0
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF831843), const Color(0xFF500724)],
        });
      }
    } else {
      // Clean fallback if DB hasn't populated kit category yet
      comboKits.addAll([
        {
          'product': null,
          'title': '4-Camera Smart Home Security Kit',
          'includes': '4x HD Cameras + 4CH DVR + 1TB Surveillance HDD + 90m Wire + SMPS',
          'price': '₹8,499',
          'originalPrice': '₹14,999',
          'discount': '43% OFF',
          'warranty': '2 Yr Warranty',
          'badge': '🔥 Top Seller',
          'gradient': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
        },
        {
          'product': null,
          'title': '8-Camera Commercial Pro Security Setup',
          'includes': '8x Night Vision Cameras + 8CH HD DVR + 2TB SkyHawk HDD + 180m Wire',
          'price': '₹15,999',
          'originalPrice': '₹26,999',
          'discount': '40% OFF',
          'warranty': '2 Yr Warranty',
          'badge': '⭐ Commercial Pro',
          'gradient': [const Color(0xFF831843), const Color(0xFF500724)],
        },
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lang.tr('cctv_combo_kits')} 📦',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(lang.tr('all_in_one_bundles'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: comboKits.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final kit = comboKits[i];
                final ProductModel? prod = kit['product'] as ProductModel?;

                return Container(
                  width: 270,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: kit['gradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE047),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kit['badge'] as String,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kit['warranty'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kit['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            kit['includes'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                kit['price'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              if ((kit['originalPrice'] as String).isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  kit['originalPrice'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              Text(
                                kit['discount'] as String,
                                style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (prod != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => ProductDetailScreen(
                                      title: prod.title,
                                      price: prod.formattedPrice,
                                      product: prod,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (c) => const ProductsScreen(initialSearchQuery: 'DVR')),
                                );
                              }
                            },
                            child: Text(lang.tr('view_kit'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // === 3. BOOK FREE CCTV SITE INSPECTION BANNER ===
  Widget _buildFreeSiteSurveyBanner(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      lang.tr('free_consultation'),
                      style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text('Tamil Nadu & Bangalore', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lang.tr('need_help_cctv'),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            lang.tr('free_site_inspection_desc'),
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const BookInstallationScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: Text(lang.tr('book_free_inspection'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  // === 4. COLORVU 24/7 NIGHT VISION SPOTLIGHT ===
  Widget _buildColorVuSpotlightCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.nightlight_round, color: Color(0xFF38BDF8), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hikvision ColorVu™ Technology', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                    Text('24/7 Vivid Full-Color in Total Darkness', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.remove_red_eye_outlined, color: Color(0xFF94A3B8), size: 18),
                      SizedBox(height: 4),
                      Text('Traditional CCTV', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                      SizedBox(height: 2),
                      Text('Black & White Grainy', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.wb_sunny_rounded, color: Color(0xFF34D399), size: 18),
                      SizedBox(height: 4),
                      Text('ColorVu 4K AI', style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('100% Full Color HD', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === 5. SK SECURITY TRUST & WARRANTY BADGES (Amazon / Flipkart Exact 4-Column Promise Strip) ===
  Widget _buildTrustAndGuaranteeStrip(BuildContext context) {
    final List<Map<String, dynamic>> badges = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Genuine',
        'subtitle': 'Warranty',
        'color': const Color(0xFF16A34A),
      },
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'Same-Day',
        'subtitle': 'Hub Dispatch',
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.engineering_rounded,
        'title': 'Certified',
        'subtitle': 'Installation',
        'color': const Color(0xFFD97706),
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '24/7 Expert',
        'subtitle': 'Tech Support',
        'color': const Color(0xFF9333EA),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 16),
              SizedBox(width: 6),
              Text(
                'SK CCTV ASSURED PROMISES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: badges.map((b) {
              final color = b['color'] as Color;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        b['icon'] as IconData,
                        size: 22,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
