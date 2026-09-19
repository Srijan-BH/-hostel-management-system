import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:hostel_management_system/core/theme/app_theme.dart';
import 'package:hostel_management_system/presentation/screens/splash_screen.dart';

import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/services/theme_service.dart';
import 'package:hostel_management_system/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService().init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      NotificationService().showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'New Alert',
        body: message.notification!.body ?? '',
      );
    }
  });
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    return MaterialApp(
      title: 'Hostel Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeService.seedColor),
      darkTheme: AppTheme.darkTheme(themeService.seedColor),
      themeMode: themeService.themeMode,
      home: const SplashScreen(),
    );
  }
}
