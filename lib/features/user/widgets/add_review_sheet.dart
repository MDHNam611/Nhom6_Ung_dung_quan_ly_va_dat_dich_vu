import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/review_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 

class AddReviewSheet extends StatefulWidget {
  final OrderModel order;
  final ReviewModel? existingReview; 

  const AddReviewSheet({
    super.key, 
    required this.order,
    this.existingReview, 
  });

  @override
  _AddReviewSheetState createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  final _commentController = TextEditingController();
  double _rating = 4.0; // Mặc định là 4 sao
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Nếu là sửa, điền thông tin cũ vào form
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn nút "Gửi đánh giá"
  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);

    // Tạo dữ liệu đánh giá dưới dạng Map
    final reviewData = {
      'orderId': widget.order.id,
      'userId': user.uid,
      'userName': user.displayName ?? 'Người dùng', 
      'userPhotoUrl': user.photoURL, 
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'timestamp': widget.existingReview?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
    };

    try {
      // Gọi hàm submitOrUpdateReview (dùng orderId làm key)
      await DatabaseService().submitOrUpdateReview(
        widget.order.serviceId, 
        widget.order.id, 
        reviewData
      );
      
      if(mounted) {
         Navigator.pop(context); // Đóng bottom sheet
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(widget.existingReview == null ? 'Cảm ơn bạn đã đánh giá!' : 'Đã cập nhật đánh giá!'),
            backgroundColor: Colors.green,
           )
         );
      }
    } catch (e) {
       if(mounted) {
         // Hiển thị lỗi nếu có (ví dụ: do Firebase Rules)
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
         );
       }
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding này giúp đẩy form lên trên khi bàn phím hiện ra
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingReview == null ? 'Bạn cảm thấy dịch vụ thế nào?' : 'Chỉnh sửa đánh giá của bạn',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),

          // Thanh chọn sao
          RatingBar.builder(
            initialRating: _rating, 
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 16),

          // Ô nhập bình luận
          TextField(
            controller: _commentController, // Đã có giá trị cũ (nếu là sửa)
            decoration: const InputDecoration(
              hintText: 'Hãy chia sẻ cảm nhận của bạn về dịch vụ...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading ? null : _submitReview,
            child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) 
                : Text(widget.existingReview == null ? 'Gửi đánh giá' : 'Cập nhật'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}