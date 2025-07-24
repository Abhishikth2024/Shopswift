import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String productId, String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return "${productId}_$sorted"
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll(', ', '_');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String productId,
    required String message,
  }) async {
    final chatId = getChatId(productId, senderId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': [senderId, receiverId],
      'productId': productId,
      'lastMessage': message,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unreadBy': [receiverId],
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await NotificationService.show("New Message", message);
  }
}
