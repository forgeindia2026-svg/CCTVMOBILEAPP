import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../../search/screens/barcode_scanner_screen.dart';
import '../../search/widgets/voice_search_bottom_sheet.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearchQuery;
  final double? maxPrice;
  final double? minPrice;

  const ProductsScreen({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
    this.maxPrice,
    this.minPrice,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isGridView = true;
  String _selectedSort = 'Popularity';
  String _searchQuery = '';
  late final TextEditingController _searchController;
  String _selectedCategory = 'All';
  String? _selectedSubCategory;
  bool _isCctvExpanded = true;

  bool _isLoading = true;
  List<ProductModel> _backendProducts = [];
  final Set<String> _wishlistedIds = {};
  
  List<String> _selectedBrands = [];
  double _selectedMinRating = 0.0;

  final List<String> _sortOptions = [
    'Popularity',
    'Price: Low to High',
    'Price: High to Low',
    'Newest First',
    'Customer Rating',
  ];

  final List<Map<String, dynamic>> _fallbackProducts = const [];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceSearch() async {
    final result = await VoiceSearchBottomSheet.show(context);
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _searchQuery = result.trim();
        _searchController.text = _searchQuery;
      });
    }
  }

  Future<void> _handleBarcodeScan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _searchQuery = result.trim();
        _searchController.text = _searchQuery;
      });
    }
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
    final listToFilter = _backendProducts.isNotEmpty ? _backendProducts : <ProductModel>[];

    return listToFilter.where((product) {
      final cat = product.category.toLowerCase().trim();
      final title = product.title.toLowerCase().trim();
      final desc = product.description.toLowerCase().trim();
      final selCat = _selectedCategory.toLowerCase().trim();

      bool matchesCategory = selCat == 'all' || selCat == 'all products' || selCat.isEmpty;
      if (!matchesCategory) {
        if (selCat == 'cctv cameras' || selCat == 'cctv' || selCat == 'cameras') {
          matchesCategory = cat.contains('ip') ||
              cat.contains('wifi') ||
              cat.contains('bullet') ||
              cat.contains('dome') ||
              cat.contains('camera') ||
              cat.contains('cctv') ||
              title.contains('camera') ||
              title.contains('cctv');
        } else if (selCat == 'dvr') {
          matchesCategory = cat.contains('dvr') || title.contains('dvr');
        } else if (selCat == 'nvr') {
          matchesCategory = cat.contains('nvr') || title.contains('nvr');
        } else if (selCat == 'accessories') {
          matchesCategory = cat.contains('accessories') ||
              cat.contains('cable') ||
              cat.contains('power') ||
              cat.contains('adapter') ||
              cat.contains('connector') ||
              title.contains('cable') ||
              title.contains('power') ||
              title.contains('smps') ||
              title.contains('adapter') ||
              title.contains('accessories');
        } else if (selCat == 'hard disk') {
          matchesCategory = cat.contains('hard') ||
              cat.contains('hdd') ||
              cat.contains('disk') ||
              title.contains('hard disk') ||
              title.contains('hdd') ||
              title.contains('terabyte') ||
              title.contains('tb') ||
              desc.contains('hdd');
        } else if (selCat == 'video door phone') {
          matchesCategory = cat.contains('door') ||
              cat.contains('vdp') ||
              cat.contains('phone') ||
              title.contains('door phone') ||
              title.contains('vdp');
        } else {
          matchesCategory = cat.contains(selCat) || title.contains(selCat);
        }
      }

      bool matchesSubCategory = true;
      if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty) {
        final sub = _selectedSubCategory!.toLowerCase().trim();
        String keyword = sub;
        if (sub == 'ip cameras') keyword = 'ip';
        else if (sub == 'wifi cameras') keyword = 'wifi';
        else if (sub == 'ptz cameras') keyword = 'ptz';
        else if (sub == 'dome cameras') keyword = 'dome';
        else if (sub == 'bullet cameras') keyword = 'bullet';

        matchesSubCategory = cat.contains(keyword) || title.contains(keyword);
      }

      final searchTerms = _searchQuery.toLowerCase().trim().split(RegExp(r'\s+'));
      final matchesSearch = _searchQuery.trim().isEmpty ||
          searchTerms.every((term) {
            if (term == 'cctv') return true;
            return title.contains(term) ||
                product.brand.toLowerCase().contains(term) ||
                cat.contains(term) ||
                desc.contains(term);
          });

      final matchesBrand = _selectedBrands.isEmpty ||
          _selectedBrands.any((selected) {
            final s = _normalizeBrandName(selected).toLowerCase();
            final pb = _normalizeBrandName(product.brand).toLowerCase();
            final pt = title.toLowerCase();
            return pb == s || pb.contains(s) || s.contains(pb) || pt.contains(s);
          });

      final matchesRating = _selectedMinRating == 0.0 || product.rating >= _selectedMinRating;
      final matchesMaxPrice = widget.maxPrice == null || product.price <= widget.maxPrice!;
      final matchesMinPrice = widget.minPrice == null || product.price >= widget.minPrice!;

      return matchesCategory &&
          matchesSubCategory &&
          matchesSearch &&
          matchesBrand &&
          matchesRating &&
          matchesMaxPrice &&
          matchesMinPrice;
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
    } else if (_selectedSort == 'Newest First') {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    } else if (_selectedSort == 'Popularity') {
      filtered.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
    }

    final lang = Provider.of<LanguageProvider>(context);

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
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: lang.tr('search_hint'),
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF475569), size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                        ),
                      ),
                    GestureDetector(
                      onTap: _handleVoiceSearch,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.mic, color: AppColors.primaryRed, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleBarcodeScan,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4, right: 10),
                        child: Icon(Icons.qr_code_scanner, color: Color(0xFF475569), size: 20),
                      ),
                    ),
                  ],
                ),
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
          // Shopping Cart with Dynamic Red Badge Count
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
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 24),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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
                // Clear All Button (if any filter is active)
                if (_selectedSort != 'Popularity' ||
                    _selectedCategory != 'All' ||
                    _selectedSubCategory != null ||
                    _selectedBrands.isNotEmpty ||
                    _selectedMinRating > 0) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSort = 'Popularity';
                        _selectedCategory = 'All';
                        _selectedSubCategory = null;
                        _selectedBrands.clear();
                        _selectedMinRating = 0.0;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryRed),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.close, size: 13, color: AppColors.primaryRed),
                          SizedBox(width: 4),
                          Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Sort Chip
                InkWell(
                  onTap: () => _showSortBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedSort != 'Popularity' ? const Color(0xFFFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedSort != 'Popularity' ? AppColors.primaryRed : const Color(0xFFD1D5DB),
                        width: _selectedSort != 'Popularity' ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedSort == 'Popularity' ? lang.tr('sort') : _selectedSort,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedSort != 'Popularity' ? FontWeight.bold : FontWeight.w500,
                            color: _selectedSort != 'Popularity' ? AppColors.primaryRed : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_vert,
                          size: 14,
                          color: _selectedSort != 'Popularity' ? AppColors.primaryRed : Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Category Filter Chip
                InkWell(
                  onTap: () => _showFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_selectedCategory != 'All' || _selectedSubCategory != null)
                          ? const Color(0xFFFEF2F2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (_selectedCategory != 'All' || _selectedSubCategory != null)
                            ? AppColors.primaryRed
                            : const Color(0xFFD1D5DB),
                        width: (_selectedCategory != 'All' || _selectedSubCategory != null) ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedSubCategory ?? (_selectedCategory != 'All' ? _selectedCategory : lang.tr('filter')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (_selectedCategory != 'All' || _selectedSubCategory != null)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: (_selectedCategory != 'All' || _selectedSubCategory != null)
                                ? AppColors.primaryRed
                                : const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 14,
                          color: (_selectedCategory != 'All' || _selectedSubCategory != null)
                              ? AppColors.primaryRed
                              : const Color(0xFF4B5563),
                        ),
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
                      color: _selectedBrands.isNotEmpty ? const Color(0xFFFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedBrands.isNotEmpty ? AppColors.primaryRed : const Color(0xFFD1D5DB),
                        width: _selectedBrands.isNotEmpty ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedBrands.isNotEmpty
                              ? (_selectedBrands.length == 1 ? _selectedBrands.first : '${lang.tr('brand')} (${_selectedBrands.length})')
                              : lang.tr('brand'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedBrands.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            color: _selectedBrands.isNotEmpty ? AppColors.primaryRed : const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: _selectedBrands.isNotEmpty ? AppColors.primaryRed : const Color(0xFF4B5563),
                        ),
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
                      color: _selectedMinRating > 0 ? const Color(0xFFFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedMinRating > 0 ? AppColors.primaryRed : const Color(0xFFD1D5DB),
                        width: _selectedMinRating > 0 ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedMinRating > 0 ? '${_selectedMinRating.toInt()}★ & up' : lang.tr('rating'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedMinRating > 0 ? FontWeight.bold : FontWeight.normal,
                            color: _selectedMinRating > 0 ? AppColors.primaryRed : const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: _selectedMinRating > 0 ? AppColors.primaryRed : const Color(0xFF4B5563),
                        ),
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
              widget.maxPrice != null
                  ? '${lang.tr('showing_products')} (${filtered.length}) • Under ₹${widget.maxPrice!.toInt()}'
                  : '${lang.tr('showing_products')} (${filtered.length})',
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
                              childAspectRatio: 0.47,
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
    final lang = Provider.of<LanguageProvider>(context);
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
                    padding: const EdgeInsets.all(4),
                    color: Colors.white,
                    child: Center(
                      child: AppImage(
                        imageUrl: item.image,
                        fit: BoxFit.contain,
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
                      // Title (Consistent 2-line height)
                      SizedBox(
                        height: 30,
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.25,
                            color: Color(0xFF212121),
                          ),
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
                                  '${item.displayRating}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, color: Colors.white, size: 9),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${item.displayReviewsCount})',
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
                          if (item.formattedOriginalPrice.isNotEmpty) ...[
                            Text(
                              item.formattedOriginalPrice,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: Color(0xFF878787),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              item.discountTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF388E3C),
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
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Big Add to Cart / Quantity Selector Button (Full width at bottom)
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final qty = cartProvider.getItemQuantity(item.id);
                          if (qty == 0) {
                            return InkWell(
                              onTap: () => cartProvider.addToCart(item),
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
                                  onTap: () => cartProvider.decrementQuantity(item.id),
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
                                  onTap: () => cartProvider.addToCart(item),
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
            // Favorite Icon at Top Right
            Consumer<WishlistProvider>(
              builder: (context, wishlist, child) {
                final isAdded = wishlist.isWishlisted(item.id);
                return Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      wishlist.toggleWishlist(item);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAdded
                              ? '${item.title} removed from Wishlist!'
                              : '${item.title} added to Wishlist! ❤️'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(
                        isAdded ? Icons.favorite : Icons.favorite_border,
                        color: isAdded ? Colors.red : const Color(0xFFC2C2C2),
                        size: 16,
                      ),
                    ),
                  ),
                );
              },
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
                  child: AppImage(
                    imageUrl: item.image,
                    fit: BoxFit.contain,
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
                          Text(' ${item.displayRating}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRedLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.discountTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
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
                    child: Builder(
                      builder: (context) {
                        int countFor(String query) {
                          final q = query.toLowerCase();
                          return _backendProducts.where((p) {
                            final c = p.category.toLowerCase();
                            final t = p.title.toLowerCase();
                            return c.contains(q) || t.contains(q);
                          }).length;
                        }

                        final ipCount = countFor('ip');
                        final wifiCount = countFor('wifi');
                        final ptzCount = countFor('ptz');
                        final domeCount = countFor('dome');
                        final bulletCount = countFor('bullet');
                        final cctvTotal = _backendProducts.where((p) {
                          final c = p.category.toLowerCase();
                          final t = p.title.toLowerCase();
                          return c.contains('camera') ||
                              c.contains('cctv') ||
                              c.contains('ip') ||
                              c.contains('wifi') ||
                              c.contains('bullet') ||
                              c.contains('dome') ||
                              t.contains('camera');
                        }).length;

                        final dvrCount = countFor('dvr');
                        final nvrCount = countFor('nvr');
                        final accCount = _backendProducts.where((p) {
                          final c = p.category.toLowerCase();
                          final t = p.title.toLowerCase();
                          return c.contains('access') || c.contains('cable') || c.contains('power') || t.contains('cable') || t.contains('smps') || t.contains('power') || t.contains('accessories');
                        }).length;
                        final hddCount = _backendProducts.where((p) {
                          final c = p.category.toLowerCase();
                          final t = p.title.toLowerCase();
                          return c.contains('hard') || c.contains('hdd') || t.contains('hard disk') || t.contains('hdd') || t.contains('terabyte');
                        }).length;
                        final vdpCount = countFor('door');

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                if (_selectedCategory != 'All' || _selectedSubCategory != null)
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedCategory = 'All';
                                        _selectedSubCategory = null;
                                      });
                                    },
                                    child: const Text('Reset', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryRow(setModalState, 'All Products', _backendProducts.length),
                            const SizedBox(height: 4),
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
                                            Text('($cctvTotal)', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
                                          _buildSubCategoryItem(setModalState, 'IP Cameras', ipCount),
                                          _buildSubCategoryItem(setModalState, 'WiFi Cameras', wifiCount),
                                          _buildSubCategoryItem(setModalState, 'PTZ Cameras', ptzCount),
                                          _buildSubCategoryItem(setModalState, 'Dome Cameras', domeCount),
                                          _buildSubCategoryItem(setModalState, 'Bullet Cameras', bulletCount),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryRow(setModalState, 'DVR', dvrCount),
                            _buildCategoryRow(setModalState, 'NVR', nvrCount),
                            _buildCategoryRow(setModalState, 'Accessories', accCount),
                            _buildCategoryRow(setModalState, 'Hard Disk', hddCount),
                            _buildCategoryRow(setModalState, 'Video Door Phone', vdpCount),
                          ],
                        );
                      },
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

  String _normalizeBrandName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final upper = trimmed.toUpperCase().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
    if (upper == 'CP PLUS' || upper == 'CPPLUS') return 'CP PLUS';
    if (upper == 'TRUE VIEW' || upper == 'TRUEVIEW') return 'Trueview';
    if (upper == 'HIK VISION' || upper == 'HIKVISION') return 'Hikvision';
    if (upper == 'DAHUA' || upper == 'DA HUA') return 'Dahua';
    if (upper == 'EZVIZ') return 'EZVIZ';
    if (upper == 'IMOU') return 'Imou';
    if (upper == 'UNV' || upper == 'UNIVIEW') return 'UNV';
    if (upper == 'TP LINK' || upper == 'TPLINK') return 'TP-Link';
    if (upper == 'CONSISTENT') return 'Consistent';
    return trimmed.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
  }

  void _showBrandBottomSheet(BuildContext context) {
    final Map<String, int> brandCounts = {};
    for (final p in _backendProducts) {
      final b = _normalizeBrandName(p.brand);
      if (b.isNotEmpty) {
        brandCounts[b] = (brandCounts[b] ?? 0) + 1;
      }
    }
    final allBrands = brandCounts.keys.toList()..sort();

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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
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
                            child: const Text('Clear All', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allBrands.length,
                      itemBuilder: (context, index) {
                        final brand = allBrands[index];
                        final count = brandCounts[brand] ?? 0;
                        final isSelected = _selectedBrands.contains(brand);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(brand, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              Text('($count)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _selectedBrands.isEmpty ? 'View All Brands' : 'Apply (${_selectedBrands.length} Selected)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                              Navigator.pop(context);
                            },
                            child: const Text('Reset', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ...ratings.map((rating) {
                    final isSelected = _selectedMinRating == rating;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMinRating = rating;
                        });
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.primaryRed : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text('${rating.toInt()}★ & above', style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const SizedBox(width: 6),
                            Row(
                              children: List.generate(
                                rating.toInt(),
                                (i) => const Icon(Icons.star, size: 15, color: Colors.amber),
                              ),
                            ),
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
      },
    );
  }
}
