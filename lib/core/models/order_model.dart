import 'package:flutter/foundation.dart';

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
      productId: json['productId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      image: json['image']?.toString() ?? '',
    );
  }

  String get formattedPrice => '₹${(price * quantity).toInt()}';

  String get fullImageUrl {
    if (image.isEmpty) return '';
    if (image.startsWith('http://') || image.startsWith('https://')) {
      if (!kIsWeb && image.contains('localhost:5000')) {
        return image.replaceAll('localhost:5000', '10.10.101.68:5000');
      }
      return image;
    }
    final host = kIsWeb ? 'http://localhost:5000' : 'http://10.10.101.68:5000';
    String path = image.startsWith('/') ? image : '/$image';
    return '$host$path';
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '#ORD-000',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      orderStatus: json['orderStatus']?.toString() ?? 'PROCESSING',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get formattedTotal => '₹${totalAmount.toInt()}';

  bool get isDelivered =>
      orderStatus.toUpperCase() == 'DELIVERED' || orderStatus.toUpperCase() == 'COMPLETED';

  bool get isProcessing =>
      orderStatus.toUpperCase() == 'PROCESSING' || orderStatus.toUpperCase() == 'IN_PROGRESS';

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
