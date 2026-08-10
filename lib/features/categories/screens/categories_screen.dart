import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../brand_products/screens/brand_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, dynamic>> _categoriesList = const [
    {'title': 'Bullet Cameras', 'subtitle': '120+ Products', 'icon': Icons.videocam_outlined},
    {'title': 'Dome Cameras', 'subtitle': '95+ Products', 'icon': Icons.camera_outlined},
    {'title': 'PTZ Cameras', 'subtitle': '60+ Products', 'icon': Icons.videocam},
    {'title': 'DVR / NVR', 'subtitle': '45+ Products', 'icon': Icons.developer_board},
    {'title': 'Wi-Fi Cameras', 'subtitle': '80+ Products', 'icon': Icons.wifi_tethering},
    {'title': 'Accessories', 'subtitle': '160+ Products', 'icon': Icons.cable},
    {'title': 'Installation Service', 'subtitle': 'Expert Installation', 'icon': Icons.engineering},
    {'title': 'Video Door Phones', 'subtitle': '40+ Products', 'icon': Icons.door_front_door_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _categoriesList.length,
          itemBuilder: (context, index) {
            final item = _categoriesList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrandProductsScreen()),
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: AppColors.primaryRed, size: 24),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}
