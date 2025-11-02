import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/review_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  final dbService = DatabaseService();
  Map<String, String> _serviceNames = {}; // Để lưu tên dịch vụ
  double? _filterByRating; // Biến trạng thái cho bộ lọc

  @override
  void initState() {
    super.initState();
    _loadServiceNames();
  }

  // Tải tên của tất cả dịch vụ một lần
  Future<void> _loadServiceNames() async {
    final snapshot = await dbService.getServicesStream().first;
    if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map;
      final names = <String, String>{};
      data.forEach((key, value) {
        if (value is Map) {
          names[key] = value['name'] ?? 'Dịch vụ không tên';
        }
      });
      if (mounted) {
        setState(() {
          _serviceNames = names;
        });
      }
    }
  }

  // Hiển thị Dialog để Admin phản hồi
  void _showReplyDialog(String serviceId, String orderId, String? currentReply) {
    final replyController = TextEditingController(text: currentReply ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phản hồi đánh giá'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung phản hồi...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              dbService.addAdminReplyToReview(serviceId, orderId, replyController.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đánh giá'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        // Thêm bộ lọc
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Lọc theo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<double>(
                  value: _filterByRating,
                  hint: const Text('Tất cả đánh giá'),
                  items: [1.0, 2.0, 3.0, 4.0, 5.0].map((rating) => 
                    DropdownMenuItem(value: rating, child: Text('$rating Sao'))
                  ).toList(),
                  onChanged: (value) => setState(() => _filterByRating = value),
                  underline: const SizedBox(),
                ),
                if (_filterByRating != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey), 
                    onPressed: () => setState(() => _filterByRating = null),
                  )
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getAllReviewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Chưa có đánh giá nào."));
          }
          
          final reviewsByService = snapshot.data!.snapshot.value as Map;
          final allReviews = <Map<String, dynamic>>[];

          reviewsByService.forEach((serviceId, reviewsMap) {
            if (reviewsMap is Map) {
              reviewsMap.forEach((orderId, reviewData) { // Key là orderId
                if (reviewData is Map) {
                  allReviews.add({
                    'serviceId': serviceId,
                    'orderId': orderId, // Lưu lại orderId
                    'review': ReviewModel.fromMap(orderId, reviewData),
                  });
                }
              });
            }
          });

          // Áp dụng bộ lọc
          var filteredReviews = allReviews;
          if (_filterByRating != null) {
            filteredReviews = filteredReviews.where((item) {
              final ReviewModel review = item['review'];
              // Lọc theo số sao, ví dụ: 5.0, 4.5, 4.0 sẽ thuộc bộ lọc 4.0
              return review.rating.floor() == _filterByRating!.floor();
            }).toList();
          }

          // Sắp xếp
          filteredReviews.sort((a, b) => b['review'].timestamp.compareTo(a['review'].timestamp));

          if (filteredReviews.isEmpty) {
             return const Center(child: Text("Không có đánh giá nào phù hợp."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: filteredReviews.length,
            itemBuilder: (context, index) {
              final item = filteredReviews[index];
              final ReviewModel review = item['review'];
              final String serviceId = item['serviceId'];
              final String orderId = item['orderId'];
              // Lấy tên dịch vụ
              final String serviceName = _serviceNames[serviceId] ?? 'Dịch vụ đã bị xóa';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: (review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(review.userPhotoUrl!)
                                : null,
                            child: (review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty)
                                ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A')
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(review.timestamp)), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xác nhận xóa'),
                                  content: const Text('Bạn có chắc muốn xóa đánh giá này? Người dùng sẽ có thể đánh giá lại đơn hàng này.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        dbService.deleteReview(serviceId, orderId);
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      RatingBarIndicator(
                        rating: review.rating,
                        itemCount: 5,
                        itemSize: 20.0,
                        itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      ),
                      const SizedBox(height: 8),
                      if (review.comment.isNotEmpty)
                        Text(review.comment, style: const TextStyle(color: Colors.black54)),
                      
                      const Divider(height: 20),
                      // Hiển thị phản hồi của Admin
                      _buildAdminReply(context, serviceId, orderId, review.adminReply),
                      
                      // Hiển thị tên dịch vụ
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.design_services_outlined, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đánh giá cho: $serviceName', 
                                style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Widget helper để hiển thị phản hồi của Admin
  Widget _buildAdminReply(BuildContext context, String serviceId, String orderId, String? reply) {
    if (reply != null && reply.isNotEmpty) {
      // Nếu đã có phản hồi -> Hiển thị nó
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phản hồi từ Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  const SizedBox(height: 4),
                  Text(reply, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              onPressed: () => _showReplyDialog(serviceId, orderId, reply),
            )
          ],
        ),
      );
    } else {
      // Nếu chưa có -> Hiển thị nút "Phản hồi"
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.reply_outlined, size: 18),
          label: const Text('Phản hồi'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          onPressed: () => _showReplyDialog(serviceId, orderId, ''),
        ),
      );
    }
  }
}