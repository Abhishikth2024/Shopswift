import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final _dbRef = FirebaseDatabase.instance.ref("products");
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getProductStream() {
    return _dbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final rawMap = Map<dynamic, dynamic>.from(data as Map);
      return rawMap.entries.map((entry) {
        final value = Map<String, dynamic>.from(entry.value as Map);

        return {
          "id": entry.key,
          "uid": value["uid"]?.toString() ?? '',
          "name": value["name"],
          "price": value["price"],
          "desc": value["desc"],
          "image": value["image"],
          "tag": value["tag"],
          "brand": value["brand"],
          "model": value["model"],
          "year": value["year"],
          "isSold": value["isSold"] ?? false,
        };
      }).toList();
    });
  }

  Future<void> addToFavorites(
    String userId,
    Map<String, dynamic> product,
  ) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(); // generates unique ID

    final productWithTrackingId = {
      ...product,
      'originalProductId': product['id'],
      'favoriteId': docRef.id,
    };

    await docRef.set(productWithTrackingId);
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .where('originalProductId', isEqualTo: productId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .where('originalProductId', isEqualTo: productId)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Map<String, dynamic>>> getFavoritesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }
}
