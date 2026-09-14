import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoadingFallback = false;
  List<ProductModel> _suggestedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestedProducts();
  }

  Future<void> _fetchSuggestedProducts() async {
    try {
      setState(() => _isLoadingFallback = true);
      final products = await ApiService.fetchProducts();
      if (mounted) {
        setState(() {
          _suggestedProducts = products.take(6).toList();
          _isLoadingFallback = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFallback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = wishlist.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          items.isNotEmpty ? 'My Wishlist (${items.length})' : 'My Wishlist',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Wishlist?'),
                    content: const Text('Are you sure you want to remove all saved items?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                        onPressed: () {
                          wishlist.clearWishlist();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildWishlistCard(context, item, wishlist, cart);
              },
            ),
    );
  }

  Widget _buildWishlistCard(
    BuildContext context,
    ProductModel item,
    WishlistProvider wishlist,
    CartProvider cart,
  ) {
    final imageUrl = item.fullImageUrl;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ProductDetailScreen(
              title: item.title,
              price: item.formattedPrice,
              product: item,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Real Image Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand.isNotEmpty ? item.brand : item.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 9),
                          ],
                        ),
                      ),
                      if (item.reviewsCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${item.reviewsCount})',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      if (item.formattedOriginalPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.formattedOriginalPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (item.discountTag.isNotEmpty && item.discountTag != 'HOT') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.discountTag,
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Delete & Add to Cart
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                  onPressed: () {
                    wishlist.removeFromWishlist(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.title} removed from Wishlist'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    cart.addToCart(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.title} added to Cart! 🛒'),
                        backgroundColor: const Color(0xFF16A34A),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 48, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Wishlist is Empty',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore our CCTV cameras & accessories and tap the heart icon to save your favourites!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 30),

          // Suggested Products Section
          if (_suggestedProducts.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'POPULAR PICKS FOR YOU',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestedProducts.length,
              itemBuilder: (ctx, i) {
                final prod = _suggestedProducts[i];
                final wishlist = Provider.of<WishlistProvider>(context, listen: false);
                final cart = Provider.of<CartProvider>(context, listen: false);
                return _buildSuggestedItemCard(context, prod, wishlist, cart);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedItemCard(
    BuildContext context,
    ProductModel item,
    WishlistProvider wishlist,
    CartProvider cart,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AppImage(
                imageUrl: item.fullImageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.primaryRed, size: 20),
            onPressed: () {
              wishlist.addToWishlist(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} added to Wishlist! ❤️'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
