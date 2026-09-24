import '../services/api_service.dart';

class OrderItemModel {
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String image;

  OrderItemModel({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      image: json['image']?.toString() ?? '',
    );
  }

  String get formattedPrice => '₹${(price * quantity).toInt()}';

  String get fullImageUrl {
    if (image.isEmpty) return '';
    if (image.startsWith('local:')) return image;
    return ApiService.resolveImageUrl(image);
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String paymentStatus;
  final String orderStatus;
  final String createdAt;
  final String category;
  final String serviceType;
  final String problemDescription;
  final String scheduledDate;
  final String scheduledTimeSlot;
  final bool hasVoiceNote;
  final String voiceNoteUrl;
  final String voiceNoteDuration;
  final List<String> images;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.category = '',
    this.serviceType = '',
    this.problemDescription = '',
    this.scheduledDate = '',
    this.scheduledTimeSlot = '',
    this.hasVoiceNote = false,
    this.voiceNoteUrl = '',
    this.voiceNoteDuration = '',
    this.images = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['siteImages'] is List) {
      parsedImages = (json['siteImages'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    }

    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '#ORD-000',
      customerName: json['customerName']?.toString() ?? json['customer']?['name']?.toString() ?? 'Customer',
      customerEmail: json['customerEmail']?.toString() ?? json['customer']?['email']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? json['customer']?['phone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? json['customer']?['address']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      orderStatus: json['orderStatus']?.toString() ?? 'PROCESSING',
      createdAt: json['createdAt']?.toString() ?? '',
      category: json['category']?.toString() ?? json['orderCategory']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      problemDescription: json['problemDescription']?.toString() ?? json['customerQuery']?.toString() ?? json['description']?.toString() ?? '',
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      scheduledTimeSlot: json['scheduledTimeSlot']?.toString() ?? '',
      hasVoiceNote: json['hasVoiceNote'] == true ||
          json['hasVoiceNote']?.toString() == 'true' ||
          (json['voiceNoteUrl']?.toString().isNotEmpty == true) ||
          (json['voiceNoteBase64']?.toString().isNotEmpty == true) ||
          (json['voiceNote']?.toString().isNotEmpty == true) ||
          (json['audioUrl']?.toString().isNotEmpty == true),
      voiceNoteUrl: json['voiceNoteUrl']?.toString() ??
          json['voiceNoteBase64']?.toString() ??
          json['voiceNote']?.toString() ??
          json['audioUrl']?.toString() ??
          '',
      voiceNoteDuration: json['voiceNoteDuration']?.toString() ?? '',
      images: parsedImages,
    );
  }

  String get formattedTotal => '₹${totalAmount.toInt()}';

  bool get isDelivered =>
      orderStatus.toUpperCase() == 'DELIVERED' || orderStatus.toUpperCase() == 'COMPLETED';

  bool get isProcessing =>
      orderStatus.toUpperCase() == 'PROCESSING' || orderStatus.toUpperCase() == 'IN_PROGRESS';

  bool get isServiceRequest {
    final cat = category.toLowerCase();
    final pDesc = problemDescription.toLowerCase();
    if (cat.contains('service') || cat.contains('installation') || cat.contains('repair') || cat.contains('amc')) {
      return true;
    }
    if (items.isNotEmpty && items.any((i) =>
        i.productId.startsWith('service-') ||
        i.title.toLowerCase().contains('installation') ||
        i.title.toLowerCase().contains('service') ||
        i.title.toLowerCase().contains('repair'))) {
      return true;
    }
    if (scheduledDate.isNotEmpty || scheduledTimeSlot.isNotEmpty || hasVoiceNote || pDesc.isNotEmpty) {
      if (items.isEmpty || (items.length == 1 && items.first.price == 0)) {
        return true;
      }
    }
    return false;
  }

  String get serviceTitle {
    if (items.isNotEmpty && items.first.title.isNotEmpty) {
      return items.first.title;
    }
    if (category.isNotEmpty) {
      return '$category Request';
    }
    return 'CCTV Service Request';
  }

  String get statusBadgeText {
    switch (orderStatus.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return 'Completed';
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }
}
