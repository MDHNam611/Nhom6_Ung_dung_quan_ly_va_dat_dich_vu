class VoucherModel {
  final String id;
  final String code;
  final int discountPercentage;
  final int createdAt;
  final int expiryAt;
  final String? ownerId;
  final bool isUsed;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    required this.createdAt,
    required this.expiryAt,
    this.ownerId,
    this.isUsed = false,
  });

  factory VoucherModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VoucherModel(
      id: id,
      code: map['code'] ?? '',
      discountPercentage: map['discountPercentage'] ?? 0,
      createdAt: map['createdAt'] ?? 0,
      expiryAt: map['expiryAt'] ?? 0,
      ownerId: map['ownerId'],
      isUsed: map['isUsed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercentage': discountPercentage,
      'createdAt': createdAt,
      'expiryAt': expiryAt,
      'ownerId': ownerId,
      'isUsed': isUsed,
    };
  }
}