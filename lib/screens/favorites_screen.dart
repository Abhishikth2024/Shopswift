import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_swift/services/product_service.dart';
import 'package:shop_swift/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view favorites')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ProductService().getFavoritesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favs = snapshot.data ?? [];

          if (favs.isEmpty) {
            return const Center(child: Text("No favorites yet."));
          }

          return ListView.builder(
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final product = favs[index];
              final name = product['name'] ?? 'Unnamed';
              final price = product['price']?.toString() ?? '0';
              final imageUrl = product['image'] ?? '';

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/default.jpg',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/default.jpg',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                ),
                title: Text(name),
                subtitle: Text(price),
                trailing: const Icon(Icons.favorite, color: Colors.red),
                onTap: () {
                  if (product['id'] == null &&
                      product['originalProductId'] != null) {
                    product['id'] = product['originalProductId'];
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
