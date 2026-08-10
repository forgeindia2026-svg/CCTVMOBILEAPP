import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../cart/screens/cart_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<Map<String, String>> _wishlistItems = [
    {
      'title': 'Hikvision 4MP Bullet Camera',
      'model': 'DS-2CD1043G0-I',
      'rating': '4.7 (89)',
      'price': '₹3,699',
      'original': '₹5,499',
      'discount': '32% OFF',
    },
    {
      'title': 'CP Plus 5MP Dome Camera',
      'model': 'CP-UNC-DA51PL3',
      'rating': '4.6 (42)',
      'price': '₹3,299',
      'original': '₹5,000',
      'discount': '34% OFF',
    },
    {
      'title': 'Dahua 4 Channel DVR',
      'model': 'DH-XVR5104C-I3',
      'rating': '4.6 (38)',
      'price': '₹2,699',
      'original': '₹3,999',
      'discount': '32% OFF',
    },
    {
      'title': 'TP-Link ViGi Wi-Fi Camera',
      'model': 'VIGI C340I',
      'rating': '4.5 (29)',
      'price': '₹2,299',
      'original': '₹3,499',
      'discount': '34% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _wishlistItems.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _wishlistItems.length,
          itemBuilder: (context, index) {
            final item = _wishlistItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.videocam, color: AppColors.primaryRed, size: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(item['model']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            Text(' ${item['rating']}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed)),
                            const SizedBox(width: 4),
                            Text(item['original']!, style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textMuted, fontSize: 10)),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRedLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(item['discount']!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions: Trash + Add to Cart button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          setState(() {
                            _wishlistItems.removeAt(index);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                        child: const Text('Add to Cart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
