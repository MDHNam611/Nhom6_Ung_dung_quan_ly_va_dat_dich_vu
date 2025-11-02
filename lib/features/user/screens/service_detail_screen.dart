import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/review_model.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/booking_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Header ảnh co giãn
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'service_image_${service.id}',
                child: CachedNetworkImage(
                  imageUrl: service.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
          
          // Nội dung chính của trang
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên dịch vụ
                  Text(
                    service.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Thẻ thông tin và hành động
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.sell_outlined, 'Giá dịch vụ', '${currencyFormatter.format(service.price)} VNĐ'),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.timer_outlined, 'Thời gian dự kiến', '${service.estimatedDuration} phút'),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Nút Yêu thích
                              StreamBuilder<bool>(
                                stream: dbService.isFavoriteStream(service.id),
                                builder: (context, snapshot) {
                                  final isFavorite = snapshot.data ?? false;
                                  return TextButton.icon(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    label: Text(
                                      isFavorite ? 'Đã thích' : 'Yêu thích',
                                      style: TextStyle(color: isFavorite ? Colors.red : Colors.black),
                                    ),
                                    onPressed: () => dbService.toggleFavoriteStatus(service.id),
                                  );
                                },
                              ),
                              // Nút Thêm vào giỏ
                              TextButton.icon(
                                icon: const Icon(Icons.add_shopping_cart_outlined, color: Colors.blue),
                                label: const Text('Thêm vào giỏ', style: TextStyle(color: Colors.black)),
                                onPressed: () {
                                  dbService.addToCart(service.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phần mô tả
                  const Text('Mô tả chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- PHẦN ĐÁNH GIÁ ---
                  const Text('Đánh giá từ khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  StreamBuilder<DatabaseEvent>(
                    stream: dbService.getReviewsForServiceStream(service.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }
                      
                      final reviewsMap = snapshot.data!.snapshot.value as Map;
                      final reviews = reviewsMap.entries.map((e) {
                        return ReviewModel.fromMap(e.key, e.value);
                      }).toList();
                      
                      reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                      double totalRating = reviews.fold(0.0, (sum, item) => sum + item.rating);
                      double avgRating = reviews.isEmpty ? 0 : totalRating / reviews.length;

                      return Column(
                        children: [
                          // Thanh đánh giá trung bình
                          Row(
                            children: [
                              Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                              const SizedBox(width: 8),
                              RatingBarIndicator(
                                rating: avgRating,
                                itemCount: 5,
                                itemSize: 20.0,
                                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                              ),
                              const SizedBox(width: 8),
                              Text('(${reviews.length} đánh giá)'),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Hiển thị 3 đánh giá gần nhất
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length > 3 ? 3 : reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return _buildReviewItem(review); // Sử dụng widget helper
                            },
                          ),
                           const SizedBox(height: 8),
                          
                          if (reviews.length > 3)
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () { 
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chức năng xem tất cả đánh giá đang phát triển'))
                                  );
                                },
                                child: const Text('Xem tất cả đánh giá'),
                              ),
                            )
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(service: service))),
            child: const Text('Đặt lịch ngay'),
          ),
        ),
      ),
    );
  }

  // Widget helper để hiển thị một dòng thông tin
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  // Widget helper để hiển thị một đánh giá (dữ liệu động)
  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh đại diện
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
                    RatingBarIndicator(
                      rating: review.rating,
                      itemCount: 5,
                      itemSize: 16.0,
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    ),
                    const SizedBox(height: 4),
                    // Bình luận của user
                    if (review.comment.isNotEmpty)
                      Text(review.comment, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              )
            ],
          ),
          
          if (review.adminReply != null && review.adminReply!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 40.0, top: 12.0), // Lùi vào
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings_outlined, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phản hồi từ Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        const SizedBox(height: 4),
                        Text(review.adminReply!, style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}