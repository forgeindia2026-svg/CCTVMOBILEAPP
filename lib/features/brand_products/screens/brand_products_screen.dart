import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class BrandProductsScreen extends StatefulWidget {
  const BrandProductsScreen({super.key});

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  int _selectedBrand = 0;
  final List<String> _brands = ['Hikvision', 'CP Plus', 'Dahua', 'UNV', 'TP-Link'];

  final List<Map<String, String>> _products = const [
    {
      'title': 'Hikvision 2MP Bullet Camera',
      'model': 'DS-2CE16D0T-ITF',
      'rating': '4.8 (128)',
      'price': '₹2,699',
      'original': '₹3,999',
      'discount': '32% OFF',
    },
    {
      'title': 'Hikvision 5MP Dome Camera',
      'model': 'DS-2CD2155FWD-I',
      'rating': '4.7 (84)',
      'price': '₹4,699',
      'original': '₹6,500',
      'discount': '29% OFF',
    },
    {
      'title': 'Hikvision 8 Channel DVR',
      'model': 'DS-7108HQHI-K1',
      'rating': '4.6 (63)',
      'price': '₹5,499',
      'original': '₹7,800',
      'discount': '29% OFF',
    },
    {
      'title': 'Hikvision 4MP PTZ Camera',
      'model': 'DS-2DE4A404IW-DE3',
      'rating': '4.8 (58)',
      'price': '₹8,999',
      'original': '₹12,999',
      'discount': '30% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brand Products'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _brands.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedBrand;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_brands[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.surfaceWhite,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedBrand = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_brands[_selectedBrand]} Products', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('120+ Products', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final item = _products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            title: item['title']!,
                            price: item['price']!,
                          ),
                        ),
                      );
                    },
                    child: Container(
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryRedLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(item['discount']!, style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ),
    );
  }
}
