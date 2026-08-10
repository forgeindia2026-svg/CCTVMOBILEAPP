import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategory;

  const ProductsScreen({super.key, this.initialCategory});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isGridView = true;
  String _selectedSort = 'Popularity';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _selectedSubCategory;
  bool _isCctvExpanded = true;

  bool _isLoading = true;
  List<ProductModel> _backendProducts = [];
  
  List<String> _selectedBrands = [];
  double _selectedMinRating = 0.0;

  final List<String> _sortOptions = [
    'Popularity',
    'Price: Low to High',
    'Price: High to Low',
    'Newest First',
    'Customer Rating',
  ];

  final List<Map<String, dynamic>> _fallbackProducts = const [
    {
      '_id': 'fallback-1',
      'title': 'Hikvision 2MP Bullet Camera',
      'model': 'DS-2CE16D0T-ITF',
      'category': 'CCTV Cameras',
      'subCategory': 'Bullet Cameras',
      'brand': 'Hikvision',
      'rating': 4.8,
      'reviewsCount': 128,
      'price': 2699.0,
      'originalPrice': 3999.0,
      'badge': '32% OFF',
      'image': 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=600&q=80',
    },
    {
      '_id': 'fallback-2',
      'title': 'CP Plus 2MP Dome Camera',
      'model': 'CP-UNC-TA21PL3C',
      'category': 'CCTV Cameras',
      'subCategory': 'Dome Cameras',
      'brand': 'CP Plus',
      'rating': 4.7,
      'reviewsCount': 96,
      'price': 2099.0,
      'originalPrice': 3299.0,
      'badge': '37% OFF',
      'image': 'https://images.unsplash.com/photo-1580894732444-8ecded7900cd?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await ApiService.fetchProducts();
      if (mounted) {
        setState(() {
          _backendProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading backend products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ProductModel> get _displayProducts {
    final List<ProductModel> listToFilter = _backendProducts.isNotEmpty
        ? _backendProducts
        : _fallbackProducts.map((e) => ProductModel.fromJson(e)).toList();

    return listToFilter.where((product) {
      final cat = product.category.toLowerCase();
      final selCat = _selectedCategory.toLowerCase();

      bool matchesCategory = selCat == 'all' || selCat == 'all products';
      if (!matchesCategory) {
        if (selCat == 'cctv cameras' || selCat == 'cctv') {
          matchesCategory = cat.contains('ip') ||
              cat.contains('bullet') ||
              cat.contains('dome') ||
              cat.contains('camera') ||
              cat.contains('cctv');
        } else if (selCat == 'dvr') {
          matchesCategory = cat.contains('dvr');
        } else if (selCat == 'nvr') {
          matchesCategory = cat.contains('nvr');
        } else if (selCat == 'accessories') {
          matchesCategory = cat.contains('accessories') || cat.contains('cable') || cat.contains('power');
        } else if (selCat == 'hard disk') {
          matchesCategory = cat.contains('hard') || cat.contains('hdd') || cat.contains('disk');
        } else if (selCat == 'video door phone') {
          matchesCategory = cat.contains('door') || cat.contains('vdp') || cat.contains('phone');
        } else {
          matchesCategory = cat.contains(selCat);
        }
      }

      bool matchesSubCategory = true;
      if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty) {
        final sub = _selectedSubCategory!.toLowerCase();
        final title = product.title.toLowerCase();
        
        // Map UI subcategory names to search keywords
        String keyword = sub;
        if (sub == 'ip cameras') keyword = 'ip';
        else if (sub == 'wifi cameras') keyword = 'wifi';
        else if (sub == 'ptz cameras') keyword = 'ptz';
        else if (sub == 'dome cameras') keyword = 'dome';
        else if (sub == 'bullet cameras') keyword = 'bullet';
        
        matchesSubCategory = cat.contains(keyword) || title.contains(keyword);
      }

      final matchesSearch = _searchQuery.isEmpty ||
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesBrand = _selectedBrands.isEmpty || _selectedBrands.contains(product.brand);
      final matchesRating = product.rating >= _selectedMinRating;

      return matchesCategory && matchesSubCategory && matchesSearch && matchesBrand && matchesRating;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _displayProducts;
    if (_selectedSort == 'Price: Low to High') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: High to Low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'Customer Rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Flipkart Exact Header Style (Matching Image 1)
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9C4), // Pale yellow background
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 24),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        // Header Search Field inside AppBar (Matching Image 1)
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            height: 42,
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'cctv camera',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF475569), size: 20),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
            ),
          ),
        ),
        actions: [
          // Shopping Cart with Red Badge Count (Matching Image 1)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '8',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB), size: 20),
            tooltip: 'Refresh Products',
            onPressed: _loadProducts,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters, Sort & Grid Switcher Bar
          // Filters, Sort & Grid Switcher Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Sort & Filter Chip
                InkWell(
                  onTap: () => _showSortBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Sort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                        SizedBox(width: 6),
                        Icon(Icons.swap_vert, size: 14, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filter Chip (Categories)
                InkWell(
                  onTap: () => _showFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Filter', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                        SizedBox(width: 6),
                        Icon(Icons.filter_alt_outlined, size: 14, color: Color(0xFF4B5563)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Brand Filter Chip
                InkWell(
                  onTap: () => _showBrandBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Brand', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF4B5563)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Rating Filter Chip
                InkWell(
                  onTap: () => _showRatingBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Rating', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF4B5563)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Grid/List View Switcher Chip
                InkWell(
                  onTap: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isGridView ? Icons.grid_view_rounded : Icons.format_list_bulleted_rounded, size: 14, color: const Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Text(_isGridView ? 'Grid View' : 'List View', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Showing X products count indicator bar
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Showing ${filtered.length} products',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Products List / Grid
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
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No Products Found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try changing filters or search terms',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.52,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildGridProductCard(context, item);
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildListProductCard(context, item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // 2-Column Grid Item Card Layout (Flipkart Style)
  Widget _buildGridProductCard(BuildContext context, ProductModel item) {
    final imageUrl = item.fullImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: item.title,
              price: item.formattedPrice,
              product: item,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section (Flipkart style: Contain within white space)
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.zero, // Removed unnecessary padding
                    color: Colors.white,
                    child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('local:') 
                          ? Image.asset(
                              'assets/images/${imageUrl.split(':')[1]}',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                            ))
                      : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand
                      Text(
                        item.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF878787),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rating & Assured Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388E3C), // Flipkart green
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.rating}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, color: Colors.white, size: 9),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${item.reviewsCount})',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF878787)),
                          ),
                          const SizedBox(width: 6),
                          // Simulated Flipkart Assured Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'SK Assured',
                              style: TextStyle(
                                fontSize: 8,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2874F0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Pricing row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            item.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (item.formattedOriginalPrice.isNotEmpty)
                            Text(
                              item.formattedOriginalPrice,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: Color(0xFF878787),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            item.discountTag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Free Delivery
                      const Text(
                        'Free Delivery',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Favorite Icon at Top Right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.favorite, color: Color(0xFFC2C2C2), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1-Column List Item Card Layout
  Widget _buildListProductCard(BuildContext context, ProductModel item) {
    final imageUrl = item.fullImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: item.title,
              price: item.formattedPrice,
              product: item,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                width: 90,
                height: 90,
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: imageUrl.isNotEmpty
                    ? (imageUrl.startsWith('local:')
                        ? Image.asset(
                            'assets/images/${imageUrl.split(':')[1]}',
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 38),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 38),
                          ))
                    : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 38),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.brand,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          Text(' ${item.rating}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed),
                      ),
                      const SizedBox(width: 6),
                      if (item.formattedOriginalPrice.isNotEmpty)
                        Text(
                          item.formattedOriginalPrice,
                          style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: AppColors.textMuted),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRedLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.discountTag,
                          style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
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

  // Filter BottomSheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.filter_alt_outlined, color: AppColors.primaryRed, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'FILTERS',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        const Text(
                          'CATEGORIES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  _isCctvExpanded = !_isCctvExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'CCTV Cameras',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Text('(11)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _isCctvExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          size: 18,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isCctvExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Color(0xFFFECDD3), width: 2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    children: [
                                      _buildSubCategoryItem(setModalState, 'IP Cameras', 6),
                                      _buildSubCategoryItem(setModalState, 'WiFi Cameras', 0),
                                      _buildSubCategoryItem(setModalState, 'PTZ Cameras', 0),
                                      _buildSubCategoryItem(setModalState, 'Dome Cameras', 0),
                                      _buildSubCategoryItem(setModalState, 'Bullet Cameras', 4),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryRow(setModalState, 'DVR', 2),
                        _buildCategoryRow(setModalState, 'NVR', 4),
                        _buildCategoryRow(setModalState, 'Accessories', 6),
                        _buildCategoryRow(setModalState, 'Hard Disk', 3),
                        _buildCategoryRow(setModalState, 'Video Door Phone', 0),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryRow(StateSetter setModalState, String name, int count) {
    final isSelected = _selectedCategory == name;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setModalState(() {
            _selectedCategory = isSelected ? 'All' : name;
            _selectedSubCategory = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  color: isSelected ? Colors.black : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryItem(StateSetter setModalState, String name, int count) {
    final isSelected = _selectedSubCategory == name;
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedSubCategory = isSelected ? null : name;
          _selectedCategory = 'CCTV Cameras';
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primaryRed : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primaryRed : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('SORT BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ..._sortOptions.map((option) {
                final isSelected = _selectedSort == option;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSort = option;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? AppColors.primaryRed : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check, color: AppColors.primaryRed, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showBrandBottomSheet(BuildContext context) {
    final allBrands = _backendProducts.isNotEmpty ? _backendProducts.map((p) => p.brand).toSet().toList() : _fallbackProducts.map((p) => p['brand'].toString()).toSet().toList();
    allBrands.sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SELECT BRAND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_selectedBrands.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedBrands.clear();
                              });
                              setState(() {});
                            },
                            child: const Text('Clear', style: TextStyle(color: AppColors.primaryRed)),
                          )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allBrands.length,
                      itemBuilder: (context, index) {
                        final brand = allBrands[index];
                        final isSelected = _selectedBrands.contains(brand);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(brand),
                          activeColor: AppColors.primaryRed,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _selectedBrands.add(brand);
                              } else {
                                _selectedBrands.remove(brand);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showRatingBottomSheet(BuildContext context) {
    final ratings = [4.0, 3.0, 2.0, 1.0];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CUSTOMER RATING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_selectedMinRating > 0)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedMinRating = 0.0;
                              });
                              setState(() {});
                            },
                            child: const Text('Clear', style: TextStyle(color: AppColors.primaryRed)),
                          )
                      ],
                    ),
                  ),
                  ...ratings.map((rating) {
                    return RadioListTile<double>(
                      value: rating,
                      groupValue: _selectedMinRating,
                      title: Row(
                        children: [
                          Text('${rating.toInt()} & above', style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      activeColor: AppColors.primaryRed,
                      onChanged: (val) {
                        setModalState(() {
                          _selectedMinRating = val ?? 0.0;
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
