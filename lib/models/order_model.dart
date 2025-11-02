// lib/models/order_model.dart

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final String bookingDate;
  final int orderTimestamp;
  final String address;
  final String status;
  final String? originalStatus;
  final String paymentMethod;
  final String? voucherCode;
  final double? discountAmount;
  final bool isReviewed; // <-- THÊM DÙNG NÀY

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.bookingDate,
    required this.orderTimestamp,
    required this.address,
    required this.status,
    this.originalStatus,
    required this.paymentMethod,
    this.voucherCode,
    this.discountAmount,
    this.isReviewed = false, 
  });

  factory OrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Không rõ',
      userEmail: map['userEmail'] ?? 'Không rõ',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0).toDouble(),
      bookingDate: map['bookingDate'] ?? '',
      orderTimestamp: map['orderTimestamp'] ?? 0,
      address: map['address'] ?? '',
      status: map['status'] ?? 'pending',
      originalStatus: map['originalStatus'],
      paymentMethod: map['paymentMethod'] ?? 'cod',
      voucherCode: map['voucherCode'],
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      isReviewed: map['isReviewed'] ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'bookingDate': bookingDate,
      'orderTimestamp': orderTimestamp,
      'address': address,
      'status': status,
      'originalStatus': originalStatus,
      'paymentMethod': paymentMethod,
      'voucherCode': voucherCode,
      'discountAmount': discountAmount,
      'isReviewed': isReviewed, 
    };
  }
}