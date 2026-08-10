import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  final List<Map<String, String>> _results = const [
    {
      'title': 'Hikvision 2MP Bullet Camera',
      'model': 'DS-2CE16D0T-ITF',
      'rating': '4.8 (128)',
      'price': '₹2,699',
      'original': '₹3,999',
      'discount': '32% OFF',
    },
    {
      'title': 'CP Plus 2MP Dome Camera',
      'model': 'CP-UNC-TA21PL3C',
      'rating': '4.7 (96)',
      'price': '₹2,099',
      'original': '₹3,299',
      'discount': '37% OFF',
    },
    {
      'title': 'Dahua 2MP Bullet Camera',
      'model': 'DH-HAC-B1A21P',
      'rating': '4.6 (78)',
      'price': '₹2,199',
      'original': '₹3,299',
      'discount': '33% OFF',
    },
    {
      'title': 'UNV 2MP Dome Camera',
      'model': 'IPC3012LR3-PF28M-D',
      'rating': '4.5 (62)',
      'price': '₹2,399',
      'original': '₹3,499',
      'discount': '32% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: TextEditingController(text: '2mp camera'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: const Icon(Icons.close, color: AppColors.textMuted),
                      fillColor: AppColors.surfaceWhite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('54 Results Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list, size: 14),
                            label: const Text('Filter', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.swap_vert, size: 14),
                            label: const Text('Sort', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
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
                                    const SizedBox(width: 4),
                                    Text(item['original']!, style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: AppColors.textMuted)),
                                    const SizedBox(width: 4),
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
