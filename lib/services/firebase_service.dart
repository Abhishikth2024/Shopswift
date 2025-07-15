import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
  }) async {
    final parts = name.trim().split(" ");
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : '';

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': '',
      'createdAt': Timestamp.now(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}
