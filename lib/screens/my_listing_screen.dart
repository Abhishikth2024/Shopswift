import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'edit_product_screen.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("products");
  final User? user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> userListings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchListings();
  }

  Future<void> fetchListings() async {
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final listings = data.entries
          .where((entry) => entry.value['uid'] == user?.uid)
          .map(
            (entry) => {
              "key": entry.key,
              ...Map<String, dynamic>.from(entry.value),
            },
          )
          .toList();

      setState(() {
        userListings = listings;
        isLoading = false;
      });
    } else {
      setState(() {
        userListings = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteListing(String key) async {
    await dbRef.child(key).remove();
    fetchListings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listings"),
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userListings.isEmpty
          ? const Center(child: Text("You have not listed any products yet."))
          : ListView.builder(
              itemCount: userListings.length,
              itemBuilder: (context, index) {
                final item = userListings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Image.asset(
                      item['image'] ?? 'assets/images/default.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item['name'] ?? ''),
                    subtitle: Text(item['desc'] ?? ''),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Edit Listing"),
                                content: const Text(
                                  "Do you want to edit this product?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Edit"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(
                                    productKey: item['key'],
                                    productData: item,
                                  ),
                                ),
                              );
                              fetchListings();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Listing"),
                                content: const Text(
                                  "Are you sure you want to delete this product?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              deleteListing(item['key']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
