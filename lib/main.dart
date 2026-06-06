import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/notification_service.dart';
import 'package:qanoon_buddy/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Auth and Notifications
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB0qW3QpJgUeaf5WOy1r1bVNKqTr_SF0Ag",
        appId: "1:192169687988:web:b1d8e70d2b799c555590e1",
        messagingSenderId: "192169687988",
        projectId: "qanoonbuddy-d60d4",
        authDomain: "qanoonbuddy-d60d4.firebaseapp.com",
        storageBucket: "qanoonbuddy-d60d4.firebasestorage.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  // Initialize Global Notifications (Safe guarded internally with kIsWeb)
  final notifService = NotificationService();
  await notifService.initialize();

  debugPrint('🚀 QANOON BUDDY BOOTING WITH PUSH NOTIFICATIONS ACTIVE');

  runApp(
    const ProviderScope(
      child: QanoonBuddyApp(),
    ),
  );
}