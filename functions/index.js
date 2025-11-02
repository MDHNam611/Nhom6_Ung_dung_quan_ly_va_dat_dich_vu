const functions = require("firebase-functions");
const admin = require("firebase-admin"); // Import Admin SDK
admin.initializeApp(); // Khởi tạo Admin SDK

// --- Ví dụ 1: Gửi thông báo khi trạng thái đơn hàng thay đổi ---
exports.notifyOrderStatusChange = functions.database
    .ref("/orders/{orderId}") // Lắng nghe thay đổi trên đường dẫn /orders/<bất kỳ orderId nào>
    .onUpdate(async (change, context) => {
      const orderDataAfter = change.after.val(); // Dữ liệu đơn hàng sau khi thay đổi
      const orderDataBefore = change.before.val(); // Dữ liệu trước khi thay đổi
      const userId = orderDataAfter.userId;
      const newStatus = orderDataAfter.status;
      const oldStatus = orderDataBefore.status;

      // Chỉ gửi thông báo nếu trạng thái thực sự thay đổi
      if (newStatus === oldStatus) {
        console.log("Status did not change.");
        return null;
      }

      // Lấy FCM token của người dùng
      const userTokenSnapshot = await admin.database()
          .ref(`/users/${userId}/fcmToken`).get();
      if (!userTokenSnapshot.exists()) {
        console.log("No token found for user:", userId);
        return null;
      }
      const token = userTokenSnapshot.val();

      // Tạo nội dung thông báo
      let notificationTitle = "Cập nhật đơn hàng";
      let notificationBody = `Đơn hàng #${context.params.orderId.substring(context.params.orderId.length - 6)} của bạn đã được cập nhật thành: ${newStatus}`;

      // Tùy chỉnh thông báo cho các trạng thái cụ thể (ví dụ)
      if (newStatus === "confirmed") {
        notificationBody = `Đơn hàng ${orderDataAfter.serviceName} đã được xác nhận!`;
      } else if (newStatus === "completed") {
        notificationBody = `Dịch vụ ${orderDataAfter.serviceName} đã hoàn thành. Hãy đánh giá nhé!`;
      } else if (newStatus === "cancelled") {
         notificationBody = `Đơn hàng ${orderDataAfter.serviceName} đã bị hủy.`;
      }

      // Tạo payload thông báo
      const payload = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        // Bạn có thể thêm data để điều hướng trong app
        // data: {
        //   screen: 'order_detail',
        //   orderId: context.params.orderId,
        // }
      };

      // Gửi thông báo đến token của người dùng
      try {
        await admin.messaging().sendToDevice(token, payload);
        console.log("Notification sent successfully to user:", userId);
      } catch (error) {
        console.error("Error sending notification:", error);
      }
      return null;
    });


// --- Ví dụ 2: Thông báo Mã giảm giá mới (Gửi cho tất cả user - Cẩn thận khi dùng) ---
// Lưu ý: Gửi cho tất cả user có thể tốn kém nếu lượng user lớn.
// Nên cân nhắc gửi theo chủ đề (topic) hoặc cho nhóm user cụ thể.
exports.notifyNewVoucher = functions.database
    .ref("/vouchers/{voucherId}")
    .onCreate(async (snapshot, context) => {
      const voucherData = snapshot.val();
      const voucherCode = voucherData.code;
      const discount = voucherData.discountPercentage;

      // Tạo payload thông báo
      const payload = {
        notification: {
          title: "🎁 Voucher Mới!",
          body: `Nhận ngay mã ${voucherCode} giảm ${discount}% cho dịch vụ!`,
        },
        // data: { screen: 'vouchers' } // Điều hướng đến trang voucher
      };

      // Lấy tất cả token của user (CÁCH NÀY KHÔNG HIỆU QUẢ VỚI NHIỀU USER)
      // const allUsersSnapshot = await admin.database().ref("/users").get();
      // if (allUsersSnapshot.exists()) {
      //   const users = allUsersSnapshot.val();
      //   const tokens = Object.values(users)
      //     .map((user) => user.fcmToken)
      //     .filter((token) => token); // Lọc bỏ token null/undefined

      //   if (tokens.length > 0) {
      //     try {
      //       // Gửi đến nhiều thiết bị (chia nhỏ nếu cần)
      //       await admin.messaging().sendToDevice(tokens, payload);
      //       console.log("Sent new voucher notification to", tokens.length, "users.");
      //     } catch (error) {
      //       console.error("Error sending multicast notification:", error);
      //     }
      //   }
      // }

      // CÁCH TỐT HƠN: Gửi theo chủ đề (topic) 'new_voucher'
      // Bạn cần cho user đăng ký topic này trong app Flutter
      try {
        await admin.messaging().sendToTopic("new_voucher", payload);
         console.log("Sent new voucher notification to topic 'new_voucher'.");
      } catch (error) {
         console.error("Error sending topic notification:", error);
      }

      return null;
    });

// --- Ví dụ 3: Nhắc lịch hẹn (Dùng Scheduled Function) ---
// Bạn cần nâng cấp lên gói Blaze để dùng Scheduled Functions
// exports.appointmentReminder = functions.pubsub
//    .schedule('every 1 hours') // Chạy mỗi giờ
//    .onRun(async (context) => {
//      // 1. Lấy danh sách các đơn hàng có lịch hẹn trong 24h tới
//      // 2. Lặp qua từng đơn hàng
//      // 3. Lấy token của user tương ứng
//      // 4. Gửi thông báo nhắc nhở
//      console.log('Running appointment reminder check...');
//      return null;
// });