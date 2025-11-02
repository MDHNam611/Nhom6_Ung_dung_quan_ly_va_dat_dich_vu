import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- LẤY VAI TRÒ NGƯỜI DÙNG ---
  Future<String?> getUserRole(String uid) async {
    try {
      final snapshot = await _dbRef.child('users/$uid/role').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as String;
      } else {
        return null; // Không tìm thấy user hoặc trường role
      }
    } catch (e) {
      print("Lỗi khi lấy vai trò người dùng: $e");
      return null;
    }
  }

  // --- XÁC THỰC BẰNG EMAIL & MẬT KHẨU ---
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await saveDeviceToken(); // Lưu token sau khi đăng nhập thành công
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        // Ghi thông tin người dùng mới vào Realtime Database
        await _dbRef.child('users/${user.uid}').set({
          'name': name,
          'email': email,
          'role': 'user' // Gán quyền user mặc định
        });
        await saveDeviceToken(); // Lưu token sau khi đăng ký thành công
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // --- XÁC THỰC BẰNG GOOGLE ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userRef = _dbRef.child('users/${user.uid}');
        final snapshot = await userRef.get();
        // Tạo profile trong DB nếu là lần đầu đăng nhập bằng Google
        if (!snapshot.exists) {
          await userRef.set({
            'name': user.displayName,
            'email': user.email,
            'role': 'user', // Gán quyền user mặc định
          });
        }
        await saveDeviceToken(); // Lưu token sau khi đăng nhập thành công
      }
      return user;
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return null;
    }
  }

  // --- LƯU FCM TOKEN ---
  Future<void> saveDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return; // Chỉ lưu khi đã đăng nhập

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Lưu token vào nhánh fcmToken của người dùng
        await _dbRef.child('users/${user.uid}/fcmToken').set(token);
        print("Đã lưu FCM Token cho user ${user.uid}");

        // Thiết lập listener để tự động cập nhật token nếu nó thay đổi
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _dbRef.child('users/${user.uid}/fcmToken').set(newToken);
          print("Đã làm mới và lưu FCM Token cho user ${user.uid}");
        });
      }
    } catch (e) {
       print("Lỗi khi lưu FCM token: $e");
    }
  }

  // --- ĐĂNG XUẤT ---
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      final isGoogleUser = user.providerData
          .any((userInfo) => userInfo.providerId == GoogleAuthProvider.PROVIDER_ID);
      if (isGoogleUser) {
        await _googleSignIn.signOut();
      }
    }
    await _auth.signOut();
  }
}