import '../services/api_service.dart';

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
  final String? warranty;
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
    this.warranty,
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
    String? foundWarranty = json['warranty']?.toString() ??
        json['warrantyPeriod']?.toString() ??
        json['warrantyDetails']?.toString() ??
        json['guarantee']?.toString() ??
        json['warranty_period']?.toString() ??
        json['warrantyInfo']?.toString();

    final rawSpecs = (json['specs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (foundWarranty == null || foundWarranty.isEmpty || foundWarranty == 'null') {
      for (final s in rawSpecs) {
        if (s.toLowerCase().contains('warrant') || s.toLowerCase().contains('year') || s.toLowerCase().contains('yr')) {
          foundWarranty = s;
          break;
        }
      }
    }

    if (foundWarranty != null && foundWarranty.isNotEmpty && foundWarranty != 'null') {
      foundWarranty = foundWarranty.trim();
      if (RegExp(r'^\d+$').hasMatch(foundWarranty)) {
        foundWarranty = '$foundWarranty Year Brand Warranty';
      } else if (!foundWarranty.toLowerCase().contains('warrant') && !foundWarranty.toLowerCase().contains('guarantee')) {
        foundWarranty = '$foundWarranty Warranty';
      }
    }

    double rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    double? rawOriginal = (json['originalPrice'] as num?)?.toDouble() ?? (json['mrp'] as num?)?.toDouble();
    double? rawOffer = (json['offerPrice'] as num?)?.toDouble() ?? (json['discountPrice'] as num?)?.toDouble();
    num? discountPercent = (json['discount'] as num?);

    double finalSellingPrice = rawPrice;
    double? finalOriginalPrice = rawOriginal;

    if (rawOffer != null && rawOffer > 0 && rawOffer < rawPrice) {
      finalSellingPrice = rawOffer;
      finalOriginalPrice = rawPrice;
    } else if (rawOriginal != null && rawOriginal > rawPrice) {
      finalSellingPrice = rawPrice;
      finalOriginalPrice = rawOriginal;
    } else if (discountPercent != null && discountPercent > 0 && (rawOriginal == null || rawOriginal <= rawPrice)) {
      // Calculate true original MRP from discount percentage
      finalOriginalPrice = (rawPrice / (1.0 - (discountPercent / 100.0))).roundToDouble();
    } else if (finalOriginalPrice != null && finalOriginalPrice <= finalSellingPrice) {
      finalOriginalPrice = null;
    }

    return ProductModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Product',
      category: json['category']?.toString() ?? 'General',
      brand: json['brand']?.toString() ?? 'SK-Vision',
      price: finalSellingPrice,
      originalPrice: finalOriginalPrice,
      badge: json['badge']?.toString(),
      warranty: foundWarranty,
      rating: ((json['rating'] as num?)?.toDouble() ?? 0.0) > 0
          ? (json['rating'] as num).toDouble()
          : (4.5 + (((json['title']?.toString().hashCode.abs() ?? 1) % 4) / 10.0)),
      reviewsCount: ((json['reviewsCount'] as num?)?.toInt() ?? 0) > 0
          ? (json['reviewsCount'] as num).toInt()
          : (48 + (((json['title']?.toString().hashCode.abs() ?? 1) + finalSellingPrice.toInt()) % 140)),
      image: json['image']?.toString() ?? '',
      specs: rawSpecs,
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

  int get displayReviewsCount {
    if (reviewsCount > 0) return reviewsCount;
    return 48 + ((title.hashCode.abs() + price.toInt()) % 140);
  }

  double get displayRating {
    if (rating > 0) return rating;
    return 4.5 + ((title.hashCode.abs() % 4) / 10.0);
  }

  String get fullImageUrl {
    if (image.isEmpty) return '';
    if (image.startsWith('local:')) return image;
    return ApiService.resolveImageUrl(image);
  }

  String get displayWarranty {
    if (warranty != null && warranty!.isNotEmpty) return warranty!;
    return '1 Yr Warranty';
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'brand': brand,
      'price': price,
      'originalPrice': originalPrice,
      'badge': badge,
      'warranty': warranty,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'image': image,
      'specs': specs,
      'stock': stock,
      'description': description,
      'isFlashDeal': isFlashDeal,
      'isBestSeller': isBestSeller,
      'features': features.map((f) => {'iconName': f.iconName, 'label': f.label}).toList(),
      'offers': offers.map((o) => {'title': o.title, 'subtitle': o.subtitle}).toList(),
    };
  }
}

