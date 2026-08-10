import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../auth/screens/login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String title;
  final String price;
  final ProductModel? product;

  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.price,
    this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoadingSimilar = true;
  List<ProductModel> _similarProducts = [];

  Future<void> _handleAddToCart(BuildContext context, ProductModel product) async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      if (!context.mounted) return;
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(returnToPrevious: true)),
      );
      if (success != true) return; // User didn't login successfully
    }
    
    if (!context.mounted) return;
    Provider.of<CartProvider>(context, listen: false).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to Cart!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleBuyNow(BuildContext context, ProductModel product) async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      if (!context.mounted) return;
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(returnToPrevious: true)),
      );
      if (success != true) return; // User didn't login successfully
    }
    
    if (!context.mounted) return;
    Provider.of<CartProvider>(context, listen: false).addToCart(product);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final titleText = p?.title ?? widget.title;
    final priceText = p?.formattedPrice ?? widget.price;
    final origPriceText = p?.formattedOriginalPrice ?? '₹3,999';
    final discountText = p?.discountTag ?? '32% OFF';
    final ratingText = p != null ? '${p.rating} (${p.reviewsCount} Reviews)' : '4.8 (128 Reviews)';
    final modelText = p != null ? (p.specs.isNotEmpty ? p.specs.first : p.category.toUpperCase()) : 'DS-2CE16D0T-ITF';
    final descriptionText = p?.description.isNotEmpty == true
        ? p!.description
        : 'High quality surveillance equipment engineered for crystal clear vision and 24/7 reliability.';
    final imageUrl = p?.fullImageUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Hero Image Box
                    Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) {
                                      return const Center(
                                        child: Icon(Icons.videocam, size: 100, color: AppColors.primaryRed),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(Icons.videocam, size: 100, color: AppColors.primaryRed),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p?.badge ?? 'Best Seller',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      titleText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modelText,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const Icon(Icons.star_half, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          ratingText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Text(
                          priceText,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryRed),
                        ),
                        const SizedBox(width: 8),
                        if (origPriceText.isNotEmpty)
                          Text(
                            origPriceText,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRedLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discountText,
                            style: const TextStyle(color: AppColors.primaryRed, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Inclusive of all taxes', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),

                    const SizedBox(height: 20),

                    // Description Section
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descriptionText,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 24),

                    // 4 Feature Circles Row
                    if (p != null && p.features.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: p.features.take(4).map((f) => _buildFeatureCircle(
                            _getIconFromName(f.iconName), f.label)).toList(),
                      )
                    else 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureCircle(Icons.camera_alt_outlined, '2 MP Full HD'),
                          _buildFeatureCircle(Icons.nightlight_round, 'Night Vision'),
                          _buildFeatureCircle(Icons.shield_outlined, 'IP67\nWeatherproof'),
                          _buildFeatureCircle(Icons.camera_sharp, '3.6mm\nLens'),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Offers Box Section
                    if (p != null && p.offers.isNotEmpty) ...[
                      Text('Offers', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...p.offers.map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildOfferTile(title: o.title, subtitle: o.subtitle),
                          )),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text('Offers', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildOfferTile(
                        title: 'Bank Offer',
                        subtitle: 'Flat 10% Instant Discount on SBI Cards',
                      ),
                      const SizedBox(height: 8),
                      _buildOfferTile(
                        title: 'No Cost EMI',
                        subtitle: 'From ₹450/month',
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Similar Products Section (Flipkart style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Similar Products', style: Theme.of(context).textTheme.titleMedium),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: FutureBuilder<List<ProductModel>>(
                        future: ApiService.fetchProducts(category: p?.category),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No similar products found.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)));
                          }
                          
                          // Filter out the current product itself
                          final similarList = snapshot.data!.where((item) => item.id != p?.id).toList();
                          
                          if (similarList.isEmpty) {
                            return const Center(child: Text('No similar products found.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)));
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similarList.length,
                            itemBuilder: (context, index) {
                              return _buildSimilarProductCard(context, similarList[index]);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Buttons: "Add to Cart" & "Buy Now"
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        side: const BorderSide(color: AppColors.primaryRed),
                      ),
                      onPressed: p == null ? null : () => _handleAddToCart(context, p),
                      child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: p == null ? null : () => _handleBuyNow(context, p),
                      child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'camera': return Icons.camera_alt_outlined;
      case 'night': return Icons.nightlight_round;
      case 'shield': return Icons.shield_outlined;
      case 'lens': return Icons.camera_sharp;
      case 'hd': return Icons.hd_outlined;
      case 'wifi': return Icons.wifi;
      case 'mic': return Icons.mic_none;
      case 'speaker': return Icons.speaker_phone;
      case 'battery': return Icons.battery_full;
      case 'storage': return Icons.sd_storage_outlined;
      case 'cloud': return Icons.cloud_outlined;
      case 'motion': return Icons.directions_run;
      case 'zoom': return Icons.zoom_in;
      case 'rotate': return Icons.screen_rotation;
      default: return Icons.check_circle_outline;
    }
  }

  Widget _buildFeatureCircle(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.1),
        ),
      ],
    );
  }

  Widget _buildOfferTile({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  // Similar Product Card Builder (Flipkart Style)
  Widget _buildSimilarProductCard(BuildContext context, ProductModel item) {
    final imageUrl = item.fullImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
                    )
                  : const Icon(Icons.videocam, color: AppColors.primaryRed, size: 40),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF212121)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C), // Flipkart green
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${item.rating}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('(${item.reviewsCount})', style: const TextStyle(fontSize: 9, color: Color(0xFF878787))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(item.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF212121))),
                      const SizedBox(width: 4),
                      if (item.formattedOriginalPrice.isNotEmpty)
                        Text(item.formattedOriginalPrice, style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 9, color: Color(0xFF878787))),
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
