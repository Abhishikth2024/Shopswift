import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shop_swift/services/notification_service.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const MyApp());

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) return;

    final Set<String> listeningChats = {};

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((chatSnapshot) {
          for (var chatDoc in chatSnapshot.docs) {
            final chatId = chatDoc.id;

            if (listeningChats.contains(chatId)) continue;
            listeningChats.add(chatId);

            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .listen((msgSnap) {
                  if (msgSnap.docs.isEmpty) return;

                  final msg = msgSnap.docs.first.data();
                  final senderId = msg['senderId'] ?? '';
                  final text = msg['text']?.toString() ?? '';

                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null || senderId == currentUser.uid)
                    return;

                  final lower = text.toLowerCase();
                  String title;
                  if (lower.contains('offer accepted')) {
                    title = 'Offer Accepted';
                  } else if (lower.contains('offer rejected')) {
                    title = 'Offer Rejected';
                  } else if (lower.contains('offered')) {
                    title = 'New Offer';
                  } else {
                    title = 'New Message';
                  }

                  NotificationService.show(title, text);
                });
          }
        });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFF500),
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD80000)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
