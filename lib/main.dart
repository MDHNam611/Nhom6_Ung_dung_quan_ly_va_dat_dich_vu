import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/auth_service.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/admin_dashboard_screen.dart';
import 'package:do_an_lap_trinh_android/features/auth/screens/login_screen.dart';
import 'package:do_an_lap_trinh_android/shared/widgets/loading_indicator.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/main_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


@pragma('vm:entry-point') 
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

// --- Kênh thông báo cho Local Notifications (Android 8.0+) ---
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', 
  'High Importance Notifications', 
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// Plugin Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // --- CÀI ĐẶT FCM ---
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Cài đặt kênh thông báo
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Hiển thị thông báo khi app đang foreground (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());

  // Yêu cầu quyền nhận thông báo
  _requestNotificationPermissions();

  // Lấy và lưu FCM token (có thể dùng trong AuthService)
  _getAndSaveDeviceToken();
}


// --- HÀM HỖ TRỢ ---

Future<void> _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
}

Future<void> _getAndSaveDeviceToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
}


// --- StatefulWidget theo dõi vòng đời và xử lý thông báo ---
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  _AppLifecycleObserverState createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver> {
  @override
  void initState() {
    super.initState();

    // Khi app đang mở (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'launch_background',
            ),
          ),
        );
      }
    });

    // Khi người dùng nhấn vào thông báo (app nền hoặc tắt)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('User opened a notification: ${message.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


// --- MyApp và AuthWrapper giữ nguyên ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MaterialApp(
        title: 'Ứng dụng Dịch vụ tại nhà',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đang chờ kết nối
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        // Nếu người dùng đã đăng nhập
        if (snapshot.hasData) {
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              if (roleSnapshot.hasData && roleSnapshot.data == 'admin') {
                return const AdminDashboardScreen();
              }

              // Nếu vai trò là user hoặc null -> MainScreen
              if (roleSnapshot.data == 'user' || roleSnapshot.data == null) {
                return const MainScreen();
              }

              return const LoginScreen();
            },
          );
        }

        // Nếu chưa đăng nhập
        return const LoginScreen();
      },
    );
  }
}
