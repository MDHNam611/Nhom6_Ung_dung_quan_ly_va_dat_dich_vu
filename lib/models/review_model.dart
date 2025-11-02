class ReviewModel {
  final String id; // Đây là orderId
  final String orderId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final int timestamp;
  final String? adminReply; // <-- THÊM TRƯỜNG MỚI NÀY

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.timestamp,
    this.adminReply, // <-- Thêm vào constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
      'adminReply': adminReply, 
    };
  }
  
  factory ReviewModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ReviewModel(
      id: id,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Người dùng ẩn danh',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      adminReply: map['adminReply'], 
    );
  }
}