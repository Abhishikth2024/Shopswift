import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  static Future<void> writeReview({
    required String targetUserId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == targetUserId) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data();
    final fullName =
        '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
    final reviewerName = fullName.isEmpty ? 'Anonymous' : fullName;

    final reviewRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('reviews')
        .doc(currentUser.uid);

    await reviewRef.set({
      'reviewerId': currentUser.uid,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _updateAverageRating(targetUserId);
  }

  static Future<void> _updateAverageRating(String userId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .get();

    final reviews = reviewsSnapshot.docs;
    final count = reviews.length;
    final totalRating = reviews.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );

    final averageRating = count == 0 ? 0 : totalRating / count;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'averageRating': averageRating,
      'reviewCount': count,
    });
  }
}
