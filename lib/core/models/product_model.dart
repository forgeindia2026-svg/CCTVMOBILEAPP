import 'package:flutter/foundation.dart';

class FeatureModel {
  final String iconName;
  final String label;

  FeatureModel({required this.iconName, required this.label});

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      iconName: json['iconName']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class OfferModel {
  final String title;
  final String subtitle;

  OfferModel({required this.title, required this.subtitle});

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}
class ProductModel {
  final String id;
  final String title;
  final String category;
  final String brand;
  final double price;
  final double? originalPrice;
  final String? badge;
  final double rating;
  final int reviewsCount;
  final String image;
  final List<String> specs;
  final int stock;
  final String description;
  final bool isFlashDeal;
  final bool isBestSeller;
  final List<FeatureModel> features;
  final List<OfferModel> offers;

  ProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.brand,
    required this.price,
    this.originalPrice,
    this.badge,
    required this.rating,
    required this.reviewsCount,
    required this.image,
    required this.specs,
    required this.stock,
    required this.description,
    required this.isFlashDeal,
    required this.isBestSeller,
    required this.features,
    required this.offers,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Product',
      category: json['category']?.toString() ?? 'General',
      brand: json['brand']?.toString() ?? 'SK-Vision',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      badge: json['badge']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      image: json['image']?.toString() ?? '',
      specs: (json['specs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stock: (json['stock'] as num?)?.toInt() ?? 10,
      description: json['description']?.toString() ?? '',
      isFlashDeal: json['isFlashDeal'] == true,
      isBestSeller: json['isBestSeller'] == true,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => FeatureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get fullImageUrl {
    if (image.isEmpty) return '';
    
    if (image.startsWith('local:')) {
      return image;
    }

    // External images (Unsplash / HTTP / HTTPS)
    if (image.startsWith('http://') || image.startsWith('https://')) {
      if (!kIsWeb && image.contains('localhost:5000')) {
        // Replace localhost with laptop local Wi-Fi IP for real physical Android phones
        return image.replaceAll('localhost:5000', '10.10.101.8:5000');
      }
      return image;
    }

    final host = kIsWeb ? 'http://localhost:5000' : 'http://10.10.101.8:5000';
    String path = image;

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    // Map local relative filenames to backend static images directory
    if (!path.startsWith('/images/')) {
      final lower = path.toLowerCase();
      if (lower.contains('dome')) {
        path = '/images/dome_camera.png';
      } else if (lower.contains('bullet')) {
        path = '/images/bullet_camera.png';
      } else if (lower.contains('ptz')) {
        path = '/images/ptz_camera.png';
      } else if (lower.contains('dvr') || lower.contains('nvr')) {
        path = '/images/dvr_nvr.png';
      } else if (lower.contains('hard') || lower.contains('hdd')) {
        path = '/images/hard_disk.png';
      } else if (lower.contains('switch') || lower.contains('poe')) {
        path = '/images/poe_switch.png';
      } else {
        path = '/images/cctv_accessories.png';
      }
    }

    return '$host$path';
  }

  String get formattedPrice => '₹${price.toInt()}';

  String get formattedOriginalPrice {
    if (originalPrice == null || originalPrice! <= price) return '';
    return '₹${originalPrice!.toInt()}';
  }

  String get discountTag {
    if (badge != null && badge!.isNotEmpty) return badge!;
    if (originalPrice != null && originalPrice! > price) {
      final percent = (((originalPrice! - price) / originalPrice!) * 100).round();
      return '$percent% OFF';
    }
    return 'HOT';
  }
}
