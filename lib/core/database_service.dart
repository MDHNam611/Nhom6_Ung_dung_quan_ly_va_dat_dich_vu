import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/category_model.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/voucher_model.dart';
import 'package:do_an_lap_trinh_android/models/address_model.dart';
import 'package:do_an_lap_trinh_android/models/review_model.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // --- Quản lý Dịch vụ ---
  Future<void> addOrUpdateService(ServiceModel service) {
    final serviceId = service.id.isEmpty ? _dbRef.child('services').push().key : service.id;
    return _dbRef.child('services/$serviceId').set(service.toMap());
  }

  Future<void> deleteService(String serviceId) {
    return _dbRef.child('services/$serviceId').remove();
  }

  Stream<DatabaseEvent> getServicesStream() {
    return _dbRef.child('services').onValue;
  }

  // --- Quản lý Danh mục ---
  Future<void> addOrUpdateCategory(CategoryModel category) {
    final categoryId = category.id.isEmpty ? _dbRef.child('categories').push().key : category.id;
    return _dbRef.child('categories/$categoryId').set(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) {
    return _dbRef.child('categories/$categoryId').remove();
  }

  Stream<DatabaseEvent> getCategoriesStream() {
    return _dbRef.child('categories').onValue;
  }

  // --- Quản lý Người dùng ---
  Stream<DatabaseEvent> getUsersStream() {
    return _dbRef.child('users').onValue;
  }

  Future<void> updateUserRole(String uid, String newRole) {
    return _dbRef.child('users/$uid/role').set(newRole);
  }

  // --- HÀM HELPER: Lấy một trường dữ liệu cụ thể của người dùng ---
  Future<DataSnapshot> getUserProfileField(String uid, String field) {
    // Truy cập trực tiếp vào trường dữ liệu cần lấy
    return _dbRef.child('users/$uid/$field').get();
  }

  // --- CẬP NHẬT THÔNG TIN USER TRONG REALTIME DB ---
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // Chỉ cập nhật tên và SĐT, không cập nhật ảnh
    return _dbRef.child('users/$uid').update(data);
  }

  // --- LOGIC YÊU THÍCH ---
  Future<void> toggleFavoriteStatus(String serviceId) async {
    if (currentUserUid == null) return;
    final favRef = _dbRef.child('favorites/$currentUserUid/$serviceId');
    final snapshot = await favRef.get();
    if (snapshot.exists) {
      await favRef.remove();
    } else {
      await favRef.set(true);
    }
  }

  Stream<bool> isFavoriteStream(String serviceId) {
    if (currentUserUid == null) return Stream.value(false);
    return _dbRef.child('favorites/$currentUserUid/$serviceId').onValue.map((event) {
      return event.snapshot.exists;
    });
  }

  Stream<List<String>> getFavoriteServiceIdsStream() {
    if (currentUserUid == null) return Stream.value([]);
    return _dbRef.child('favorites/$currentUserUid').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      // Đảm bảo dữ liệu là Map trước khi cast
      if (event.snapshot.value is Map) {
         final favsMap = event.snapshot.value as Map<dynamic, dynamic>;
         return favsMap.keys.cast<String>().toList();
      }
      return []; // Trả về list rỗng nếu kiểu dữ liệu không đúng
    });
  }

  // --- LOGIC GIỎ HÀNG ---
  Future<void> addToCart(String serviceId) async {
    if (currentUserUid == null) return;
    await _dbRef.child('carts/$currentUserUid/$serviceId').set(true);
  }

  Future<void> removeFromCart(String serviceId) async {
    if (currentUserUid == null) return;
    await _dbRef.child('carts/$currentUserUid/$serviceId').remove();
  }

  Future<void> clearCart() async {
    if (currentUserUid == null) return;
    await _dbRef.child('carts/$currentUserUid').remove();
  }

  Stream<List<String>> getCartServiceIdsStream() {
    if (currentUserUid == null) return Stream.value([]);
    return _dbRef.child('carts/$currentUserUid').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
       if (event.snapshot.value is Map) {
         final cartMap = event.snapshot.value as Map<dynamic, dynamic>;
         return cartMap.keys.cast<String>().toList();
       }
       return [];
    });
  }

  // --- LOGIC ĐƠN HÀNG (Sử dụng trạng thái tiếng Anh) ---

  Future<void> placeOrder(OrderModel order) {
    final newOrderRef = _dbRef.child('orders').push();
    return newOrderRef.set(order.toMap());
  }

  Stream<DatabaseEvent> getAllOrdersStream() {
    // Sắp xếp theo timestamp để lấy đơn mới nhất trước
    return _dbRef.child('orders').orderByChild('orderTimestamp').onValue;
  }

  Stream<DatabaseEvent> getUserOrdersStream() {
    if (currentUserUid == null) return const Stream.empty();
    // Truy vấn các đơn hàng của user hiện tại
    return _dbRef.child('orders').orderByChild('userId').equalTo(currentUserUid).onValue;
  }

  // Admin cập nhật trạng thái đơn hàng (sử dụng chuỗi tiếng Anh)
  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _dbRef.child('orders/$orderId/status').set(newStatus);
  }

  // User gửi yêu cầu hủy (lưu trạng thái tiếng Anh)
  Future<void> requestOrderCancellation(String orderId, String currentStatus) {
    return _dbRef.child('orders/$orderId').update({
      'status': 'awaiting_cancellation',
      'originalStatus': currentStatus,
    });
  }

  // Admin đồng ý hủy (cập nhật trạng thái tiếng Anh)
  Future<void> approveCancellation(String orderId) {
    return _dbRef.child('orders/$orderId').update({
      'status': 'cancelled',
      'originalStatus': null,
    });
  }

  // Admin từ chối hủy (cập nhật trạng thái tiếng Anh)
  Future<void> denyCancellation(String orderId, String originalStatus) {
    return _dbRef.child('orders/$orderId').update({
      'status': originalStatus,
      'originalStatus': null,
    });
  }

  // --- LOGIC MÃ GIẢM GIÁ ---

  Future<void> addOrUpdateVoucher(VoucherModel voucher) {
    final voucherId = voucher.id.isEmpty ? _dbRef.child('vouchers').push().key : voucher.id;
    return _dbRef.child('vouchers/$voucherId').set(voucher.toMap());
  }

  Future<void> deleteVoucher(String voucherId) {
    return _dbRef.child('vouchers/$voucherId').remove();
  }

  Stream<DatabaseEvent> getAllVouchersStream() {
    return _dbRef.child('vouchers').orderByChild('createdAt').onValue;
  }

  Stream<DatabaseEvent> getUserVouchersStream() {
    if (currentUserUid == null) return const Stream.empty();
    return _dbRef.child('vouchers').orderByChild('ownerId').equalTo(currentUserUid).onValue;
  }

  Future<VoucherModel> claimRandomVoucher() async {
    if (currentUserUid == null) throw Exception('Bạn cần đăng nhập.');

    final availableVouchersSnapshot = await _dbRef.child('vouchers').orderByChild('ownerId').equalTo(null).limitToFirst(1).get();
    if (!availableVouchersSnapshot.exists || availableVouchersSnapshot.value == null) {
      // Sửa đổi bởi Gemini: Thay đổi Exception thành String để UI hiển thị thông báo thân thiện hơn.
      throw 'Rất tiếc, đã hết mã giảm giá.';
    }

    // Firebase trả về Map<dynamic, dynamic>, cần lấy key và value đầu tiên
    final data = availableVouchersSnapshot.value as Map<dynamic, dynamic>;
    final voucherId = data.keys.first;
    final voucherData = data[voucherId];

    // Kiểm tra kiểu dữ liệu của voucherData trước khi cast
    if (voucherData is Map) {
      final voucher = VoucherModel.fromMap(voucherId, voucherData);

      // Gán mã cho người dùng
      await _dbRef.child('vouchers/$voucherId/ownerId').set(currentUserUid);

      return voucher;
    } else {
      throw Exception('Dữ liệu voucher không hợp lệ.');
    }
  }


  Future<VoucherModel> validateAndGetVoucher(String code) async {
    if (currentUserUid == null) throw Exception('User not logged in.');
    final upperCaseCode = code.toUpperCase();

    final query = _dbRef.child('vouchers').orderByChild('code').equalTo(upperCaseCode).limitToFirst(1);
    final snapshot = await query.get();

    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Mã giảm giá không hợp lệ.');
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final voucherId = data.keys.first;
    final voucherData = data.values.first;

    if (voucherData is Map) {
        final voucher = VoucherModel.fromMap(voucherId, voucherData);

        if (voucher.ownerId != currentUserUid) {
          throw Exception('Mã này không thuộc về bạn.');
        }
        if (voucher.isUsed) {
          throw Exception('Mã này đã được sử dụng.');
        }
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(voucher.expiryAt);
        if (DateTime.now().isAfter(expiryDate)) {
          throw Exception('Mã này đã hết hạn.');
        }
        return voucher;
    } else {
       throw Exception('Dữ liệu voucher không hợp lệ.');
    }
  }


  Future<void> markVoucherAsUsed(String voucherId) {
    return _dbRef.child('vouchers/$voucherId').update({'isUsed': true});
  }

  // --- CÁC HÀM LẤY THỐNG KÊ ---
  Stream<int> getUserCountStream() {
    return _dbRef.child('users').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return (event.snapshot.value as Map).length;
      }
      return 0;
    });
  }

  Stream<int> getOrderCountStream() {
    return _dbRef.child('orders').onValue.map((event) {
       if (event.snapshot.exists && event.snapshot.value is Map) {
         return (event.snapshot.value as Map).length;
       }
      return 0;
    });
  }

  Stream<int> getServiceCountStream() {
    return _dbRef.child('services').onValue.map((event) {
       if (event.snapshot.exists && event.snapshot.value is Map) {
         return (event.snapshot.value as Map).length;
       }
      return 0;
    });
  }

  // --- LOGIC QUẢN LÝ ĐỊA CHỈ (THÊM MỚI) ---

  // Lấy stream danh sách địa chỉ của người dùng
  Stream<DatabaseEvent> getUserAddressesStream() {
    if (currentUserUid == null) return const Stream.empty();
    return _dbRef.child('addresses/$currentUserUid').onValue;
  }

  // Thêm địa chỉ mới
  Future<String?> addAddress(AddressModel address) async {
    if (currentUserUid == null) return null;
    final newAddressRef = _dbRef.child('addresses/$currentUserUid').push();
    await newAddressRef.set(address.toMap());
    return newAddressRef.key; // Trả về ID của địa chỉ mới tạo
  }

  // Cập nhật địa chỉ
  Future<void> updateAddress(AddressModel address) {
    if (currentUserUid == null) return Future.value();
    return _dbRef.child('addresses/$currentUserUid/${address.id}').update(address.toMap());
  }

  // Xóa địa chỉ
  Future<void> deleteAddress(String addressId) {
    if (currentUserUid == null) return Future.value();
    return _dbRef.child('addresses/$currentUserUid/$addressId').remove();
  }

  // Đặt địa chỉ làm mặc định
  Future<void> setDefaultAddress(String newDefaultAddressId) async {
    if (currentUserUid == null) return;
    final userAddressRef = _dbRef.child('addresses/$currentUserUid');
    final userProfileRef = _dbRef.child('users/$currentUserUid');

    // 1. Lấy địa chỉ mặc định cũ (nếu có)
    final defaultAddressIdSnapshot = await userProfileRef.child('defaultAddressId').get();
    String? oldDefaultId;
    if (defaultAddressIdSnapshot.exists && defaultAddressIdSnapshot.value != null) {
      oldDefaultId = defaultAddressIdSnapshot.value as String;
    }

    // 2. Tạo Map chứa các cập nhật cần thực hiện
    Map<String, dynamic> updates = {};
    // Bỏ cờ mặc định ở địa chỉ cũ (nếu có và khác địa chỉ mới)
    if (oldDefaultId != null && oldDefaultId != newDefaultAddressId) {
      updates['$oldDefaultId/isDefault'] = false;
    }
    // Đặt cờ mặc định cho địa chỉ mới
    updates['$newDefaultAddressId/isDefault'] = true;

    // 3. Cập nhật đồng thời cờ isDefault trong nhánh addresses
    await userAddressRef.update(updates);

    // 4. Cập nhật defaultAddressId trong hồ sơ người dùng
    await userProfileRef.update({'defaultAddressId': newDefaultAddressId});
  }

   // Lấy thông tin địa chỉ mặc định
  Future<AddressModel?> getDefaultAddress() async {
    if (currentUserUid == null) return null;
    final userProfileRef = _dbRef.child('users/$currentUserUid');
    final defaultAddressIdSnapshot = await userProfileRef.child('defaultAddressId').get();

    if (defaultAddressIdSnapshot.exists && defaultAddressIdSnapshot.value != null) {
      final defaultId = defaultAddressIdSnapshot.value as String;
      final addressSnapshot = await _dbRef.child('addresses/$currentUserUid/$defaultId').get();
      if (addressSnapshot.exists) {
        return AddressModel.fromMap(defaultId, addressSnapshot.value as Map);
      }
    }
    return null; // Không có địa chỉ mặc định hoặc không tìm thấy
  }

  // --- LOGIC ĐÁNH GIÁ (REVIEW) ---

  Future<void> submitOrUpdateReview(String serviceId, String orderId, Map<String, dynamic> reviewData) async {
    await _dbRef.child('reviews/$serviceId/$orderId').set(reviewData);
    await _dbRef.child('orders/$orderId/isReviewed').set(true);
  }

  Stream<DatabaseEvent> getReviewsForServiceStream(String serviceId) {
    return _dbRef.child('reviews/$serviceId').orderByChild('timestamp').onValue;
  }
  
  Future<ReviewModel?> getReviewForOrder(String serviceId, String orderId) async {
    final snapshot = await _dbRef.child('reviews/$serviceId/$orderId').get();
    if (snapshot.exists && snapshot.value != null) {
      return ReviewModel.fromMap(orderId, snapshot.value as Map);
    }
    return null;
  }
  
  Stream<DatabaseEvent> getAllReviewsStream() {
    return _dbRef.child('reviews').onValue;
  }

  // Admin: Xóa một đánh giá
  Future<void> deleteReview(String serviceId, String orderId) async {
    // 1. Xóa đánh giá
    await _dbRef.child('reviews/$serviceId/$orderId').remove();
    // 2. Đặt lại trạng thái isReviewed của đơn hàng thành false
    await _dbRef.child('orders/$orderId/isReviewed').set(false);
  }

  Future<void> addAdminReplyToReview(String serviceId, String orderId, String reply) {
    return _dbRef.child('reviews/$serviceId/$orderId').update({
      'adminReply': reply
    });
  }

  // --- LOGIC TRUNG TÂM TRỢ GIÚP (FAQs) ---
  Stream<DatabaseEvent> getFaqsStream() {
    return _dbRef.child('faqs').onValue;
  }
}