import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/wishlist_provider.dart';
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
  bool _isFavorited = false;
  String _deliveryAddress = LocationService.defaultAddress;

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
  }

  void _loadDeliveryAddress() async {
    final addr = await LocationService.getSavedAddress();
    if (mounted) {
      setState(() {
        _deliveryAddress = addr;
      });
    }
  }

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
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              final isFavorited = widget.product != null
                  ? wishlist.isWishlisted(widget.product!.id)
                  : _isFavorited;
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : Colors.black,
                ),
                onPressed: () {
                  if (widget.product != null) {
                    wishlist.toggleWishlist(widget.product!);
                  } else {
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });
                  }
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!isFavorited
                          ? '$titleText added to Wishlist! ❤️'
                          : '$titleText removed from Wishlist!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () => _showShareModal(context, p, titleText, priceText),
          ),
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
                            child: AppImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
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
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (modelText.isNotEmpty)
                      Text(
                        modelText,
                        style: const TextStyle(color: Color(0xFF878787), fontSize: 12, fontWeight: FontWeight.normal),
                      ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C), // Flipkart Green rating pill
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '4.6',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.star, color: Colors.white, size: 10),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ratingText,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF878787)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceText,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                        ),
                        const SizedBox(width: 8),
                        if (origPriceText.isNotEmpty) ...[
                          Text(
                            origPriceText,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Color(0xFF878787),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (discountText.isNotEmpty)
                          Text(
                            discountText,
                            style: const TextStyle(
                              color: Color(0xFF388E3C), // Flipkart Green
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Inclusive of all taxes', style: TextStyle(color: Color(0xFF878787), fontSize: 11)),

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

                    // 4 Feature Circles Row (Dynamic from Admin or Auto-detected from Specs)
                    _buildDynamicFeatureCircles(p),

                    const SizedBox(height: 24),

                    // Flipkart Style Delivery Details Card
                    _buildDeliveryDetailsCard(context),

                    const SizedBox(height: 16),

                    // Official Brand Warranty & Service Box (Flipkart/Amazon style)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p?.displayWarranty ?? '1 Year Brand Warranty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF14532D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '100% Genuine Product • Official Service Support • Repair & Replacement Guarantee',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      Text('Offers & Benefits', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildOfferTile(
                        icon: Icons.build_circle_outlined,
                        title: 'Installation Offer',
                        subtitle: 'Free Site Survey & Standard Installation Support',
                      ),
                      const SizedBox(height: 8),
                      _buildOfferTile(
                        icon: Icons.inventory_2_outlined,
                        title: 'Combo Pack Deal',
                        subtitle: 'Save extra on Camera + DVR/NVR & HDD installation kits',
                      ),
                      const SizedBox(height: 8),
                      _buildOfferTile(
                        icon: Icons.payments_outlined,
                        title: 'Pay After Installation',
                        subtitle: '100% Cash on Delivery — Pay technician after testing',
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

  Widget _buildDynamicFeatureCircles(ProductModel? p) {
    if (p != null && p.features.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: p.features.take(4).map((f) => _buildFeatureCircle(_getIconFromName(f.iconName), f.label)).toList(),
      );
    }

    final String text = '${p?.title ?? ''} ${p?.specs.join(' ') ?? ''} ${p?.description ?? ''}'.toLowerCase();

    // 1. Resolution Badge
    IconData resIcon = Icons.camera_alt_outlined;
    String resLabel = '2 MP Full HD';
    if (text.contains('5mp') || text.contains('5 mp')) {
      resIcon = Icons.hd_outlined;
      resLabel = '5 MP Ultra HD';
    } else if (text.contains('4mp') || text.contains('4 mp')) {
      resIcon = Icons.hd_outlined;
      resLabel = '4 MP Quad HD';
    } else if (text.contains('3mp') || text.contains('3 mp')) {
      resIcon = Icons.hd_outlined;
      resLabel = '3 MP 2K HD';
    } else if (text.contains('1080p') || text.contains('2mp') || text.contains('2 mp')) {
      resIcon = Icons.camera_alt_outlined;
      resLabel = '2 MP Full HD';
    } else if (text.contains('dvr') || text.contains('nvr')) {
      resIcon = Icons.dns_outlined;
      resLabel = 'Multi-Channel';
    } else if (text.contains('tb') || text.contains('hdd') || text.contains('hard disk')) {
      resIcon = Icons.sd_storage_outlined;
      resLabel = 'Surveillance Storage';
    }

    // 2. Vision / Night Vision
    IconData visionIcon = Icons.nightlight_round;
    String visionLabel = 'Night Vision';
    if (text.contains('duovision') || text.contains('warm light') || text.contains('color')) {
      visionIcon = Icons.lightbulb_outline;
      visionLabel = 'Color Night\nVision';
    } else if (text.contains('ir') || text.contains('night')) {
      visionIcon = Icons.nightlight_round;
      visionLabel = '40M IR Night\nVision';
    } else if (text.contains('lens') || text.contains('wide')) {
      visionIcon = Icons.camera_sharp;
      visionLabel = 'Wide-Angle\nCoverage';
    }

    // 3. Weatherproof / Build / Audio
    IconData buildIcon = Icons.shield_outlined;
    String buildLabel = 'IP67\nWeatherproof';
    if (text.contains('ip67')) {
      buildIcon = Icons.shield_outlined;
      buildLabel = 'IP67\nWeatherproof';
    } else if (text.contains('ip66')) {
      buildIcon = Icons.shield_outlined;
      buildLabel = 'IP66\nWeatherproof';
    } else if (text.contains('mic') || text.contains('audio')) {
      buildIcon = Icons.mic_none;
      buildLabel = 'Built-in\nMic Audio';
    } else if (text.contains('ptz') || text.contains('pan') || text.contains('tilt') || text.contains('360')) {
      buildIcon = Icons.screen_rotation;
      buildLabel = '360° Pan\n& Tilt';
    }

    // 4. Smart Feature / AI / Connectivity
    IconData extraIcon = Icons.camera_sharp;
    String extraLabel = '3.6mm\nLens';
    if (text.contains('ai') || text.contains('human') || text.contains('detection')) {
      extraIcon = Icons.directions_run;
      extraLabel = 'AI Human\nDetection';
    } else if (text.contains('mic') && !buildLabel.contains('Mic')) {
      extraIcon = Icons.mic_none;
      extraLabel = 'Built-in\nMic';
    } else if (text.contains('wifi') || text.contains('wireless')) {
      extraIcon = Icons.wifi;
      extraLabel = 'WiFi\nWireless';
    } else if (text.contains('sd') || text.contains('card')) {
      extraIcon = Icons.sd_storage_outlined;
      extraLabel = 'SD Card\nSlot';
    } else if (text.contains('onvif') || text.contains('poe')) {
      extraIcon = Icons.settings_input_hdmi;
      extraLabel = 'ONVIF / PoE\nReady';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeatureCircle(resIcon, resLabel),
        _buildFeatureCircle(visionIcon, visionLabel),
        _buildFeatureCircle(buildIcon, buildLabel),
        _buildFeatureCircle(extraIcon, extraLabel),
      ],
    );
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

  Widget _buildOfferTile({IconData? icon, required String title, required String subtitle, String? details}) {
    return InkWell(
      onTap: () => _showOfferDetailModal(title, subtitle, icon, details),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon ?? Icons.local_offer_outlined, color: AppColors.primaryRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showOfferDetailModal(String title, String subtitle, IconData? icon, String? customDetails) {
    List<String> terms = [];
    String highlight = '';

    if (title.toLowerCase().contains('install')) {
      highlight = 'Free Site Inspection & Standard Installation Support';
      terms = [
        'Certified CCTV technician visits your location directly.',
        'Standard mounting, camera angle calibration & wiring assistance included.',
        'Complete mobile app live view setup on your smartphone.',
        'No coupon code needed — automatically verified with your order.',
      ];
    } else if (title.toLowerCase().contains('combo')) {
      highlight = 'Save Extra on Camera + DVR/NVR + Hard Disk Pack';
      terms = [
        'Special bundled price when selecting complete security setup.',
        'Guaranteed 100% genuine & compatible hardware parts.',
        'Full manufacturer warranty applies on all combo items.',
        'Technician tests all connected cameras during installation.',
      ];
    } else if (title.toLowerCase().contains('pay') || title.toLowerCase().contains('delivery') || title.toLowerCase().contains('cash')) {
      highlight = '100% Cash on Delivery & Pay After Installation';
      terms = [
        'No advance online payment required.',
        'Pay technician directly only after complete delivery & installation testing.',
        'Check live video clarity on your mobile app before paying.',
        'Receive official digital invoice & warranty card immediately.',
      ];
    } else {
      highlight = subtitle;
      terms = [
        customDetails ?? 'Special limited-time promotional offer from SK Tech CCTV.',
        'Applicable on this product for all orders placed through the app.',
        'Combined with standard brand warranty and free technical support.',
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon ?? Icons.local_offer_outlined, color: AppColors.primaryRed, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF14532D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Offer Details & Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  ...terms.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(Icons.circle, size: 5, color: AppColors.primaryRed),
                            ),
                            Expanded(
                              child: Text(t, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.35)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Similar Product Card Builder (Flipkart Style)
  Widget _buildSimilarProductCard(BuildContext context, ProductModel item) {
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
              child: AppImage(
                imageUrl: item.image,
                fit: BoxFit.contain,
              ),
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

  Widget _buildDeliveryDetailsCard(BuildContext context) {
    // Dynamic Delivery Estimate calculated against Shoolagiri (635117) Warehouse
    final estimate = LocationService.calculateDeliveryEstimate(_deliveryAddress);
    final DateTime deliveryDate = estimate['deliveryDate'] as DateTime;
    final formattedDate = DateFormat('d MMM, EEE').format(deliveryDate);
    final isTomorrow = estimate['isTomorrow'] as bool;
    final countdownText = estimate['countdownText'] as String;
    final badge = estimate['badge'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              // 1. Delivery Location Row (Clickable)
              InkWell(
                onTap: () async {
                  final selected = await LocationService.showLocationPicker(context, _deliveryAddress);
                  if (selected != null && mounted) {
                    setState(() {
                      _deliveryAddress = selected;
                    });
                  }
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF1E293B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _deliveryAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
                    ],
                  ),
                ),
              ),

              // 2. Delivery Date & Fast Dispatch Row (Shoolagiri Hub)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTomorrow ? 'Delivery by Tomorrow, $formattedDate' : 'Delivery by $formattedDate',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  countdownText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 3. Certified Seller / Fulfilled Row (Shoolagiri Hub)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: Color(0xFF475569), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fulfilled by SK Technologies CCTV Hub',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('4.8', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 2),
                                    Icon(Icons.star, color: Colors.white, size: 9),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  '• Shoolagiri Hub (635117)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
            ],
          ),
        ),
      ],
    );
  }

  void _showShareModal(BuildContext context, ProductModel? p, String titleText, String priceText) {
    final String shareContent = '''
📹 *$titleText*
💰 *Price:* $priceText
🛡️ *Warranty:* ${p?.displayWarranty ?? '1 Year Brand Warranty'}
🚚 *Delivery:* Free Delivery across Tamil Nadu & Bangalore
💵 *Payment:* 100% Cash on Delivery & Pay After Installation

Check it out on SK Tech CCTV App!
''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.share, color: AppColors.primaryRed, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Share Product',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 6),

                // Product Card Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: AppImage(
                          imageUrl: p?.fullImageUrl ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  priceText,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryRed),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Free Delivery',
                                    style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold),
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

                const SizedBox(height: 20),

                // Share Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareAction(
                      icon: Icons.copy,
                      label: 'Copy Details',
                      bgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareContent));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product details copied to clipboard! 📋'),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      bgColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareContent));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message copied! Paste in WhatsApp to share 💬'),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.message_outlined,
                      label: 'SMS / Text',
                      bgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareContent));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message copied! Ready to send via SMS ✉️'),
                            backgroundColor: Color(0xFFD97706),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.link,
                      label: 'Copy Link',
                      bgColor: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: 'https://sktechcctv.com/products/${p?.id ?? 'cctv'}'));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product web link copied to clipboard! 🔗'),
                            backgroundColor: Color(0xFF9333EA),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
