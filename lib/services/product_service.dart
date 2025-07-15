import 'package:firebase_database/firebase_database.dart';

class ProductService {
  final _dbRef = FirebaseDatabase.instance.ref("products");

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
        };
      }).toList();
    });
  }
}
