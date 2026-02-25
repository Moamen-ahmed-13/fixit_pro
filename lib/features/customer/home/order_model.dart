import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  assigned,
  onTheWay,
  inProgress,
  completed,
  cancelled,
}

enum SlaType { normal, urgent, emergency }

class OrderModel {
  final String id;
  final String customerId;
  final String? technicianId;
  final String deviceType;
  final String brand;
  final String issue;
  final OrderStatus status;
  final SlaType slaType;
  final String address;
  final GeoPoint? location;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final double? estimatedPriceMin;
  final double? estimatedPriceMax;
  final double? finalPrice;
  final String paymentMethod;
  final double? rating;

  const OrderModel({
    required this.id,
    required this.customerId,
    this.technicianId,
    required this.deviceType,
    required this.brand,
    required this.issue,
    required this.status,
    required this.slaType,
    required this.address,
    this.location,
    required this.scheduledAt,
    required this.createdAt,
    this.estimatedPriceMin,
    this.estimatedPriceMax,
    this.finalPrice,
    this.paymentMethod = 'cash',
    this.rating,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: d['customerId'] ?? '',
      technicianId: d['technicianId'],
      deviceType: d['deviceType'] ?? '',
      brand: d['brand'] ?? '',
      issue: d['issue'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => OrderStatus.pending,
      ),
      slaType: SlaType.values.firstWhere(
        (e) => e.name == d['slaType'],
        orElse: () => SlaType.normal,
      ),
      address: d['address'] ?? '',
      location: d['location'],
      scheduledAt: (d['scheduledAt'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      estimatedPriceMin: (d['estimatedPriceMin'] as num?)?.toDouble(),
      estimatedPriceMax: (d['estimatedPriceMax'] as num?)?.toDouble(),
      finalPrice: (d['finalPrice'] as num?)?.toDouble(),
      paymentMethod: d['paymentMethod'] ?? 'cash',
      rating: (d['rating'] as num?)?.toDouble(),
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:    return 'انتظار فني';
      case OrderStatus.assigned:   return 'تم التعيين';
      case OrderStatus.onTheWay:   return 'في الطريق';
      case OrderStatus.inProgress: return 'جاري التنفيذ';
      case OrderStatus.completed:  return 'مكتمل';
      case OrderStatus.cancelled:  return 'ملغي';
    }
  }

  String get deviceEmoji {
    switch (deviceType) {
      case 'ac':        return '❄️';
      case 'fridge':    return '🧊';
      case 'washer':    return '🫧';
      case 'gas':       return '🔥';
      case 'tv':        return '📺';
      case 'heater':    return '♨️';
      default:          return '🔧';
    }
  }
}
