import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  Stream<DatabaseEvent> getAllProducts() {
    return FirebaseDatabase.instance.ref('products').onValue;
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseDatabase.instance.ref('products/$productId').remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Products"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No products available."));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final entries = data.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final productId = entries[index].key.toString();
              final productData = Map<String, dynamic>.from(
                entries[index].value,
              );

              final name = productData['name'] ?? 'No Name';
              final seller = productData['uid'] ?? 'Unknown';
              final imageUrl = productData['image'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(name),
                  subtitle: Text('Posted by: $seller'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: const Text(
                            "Are you sure you want to delete this product?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await deleteProduct(productId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Product deleted")),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
