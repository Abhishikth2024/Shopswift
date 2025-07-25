// KEEP IMPORTS UNCHANGED
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_swift/widgets/custom_nav_drawer.dart';
import 'package:shop_swift/services/product_service.dart';
import 'package:shop_swift/screens/add_product_screen.dart';
import 'package:shop_swift/screens/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isGoogleSignIn = false});
  final bool isGoogleSignIn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService productService = ProductService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser;
  bool get isGuest => currentUser?.isAnonymous ?? false;

  void _openSearchPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Search & Filter"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: "Search by name",
                  ),
                ),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: "Brand"),
                ),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: "Model"),
                ),
                TextField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Year"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Apply Filter"),
            ),
            TextButton(
              onPressed: () {
                searchController.clear();
                brandController.clear();
                modelController.clear();
                yearController.clear();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomNavDrawer(isGoogleSignIn: widget.isGoogleSignIn),
      appBar: AppBar(
        title: const Text("ShopSwift"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to ShopSwift!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Explore amazing car parts near you.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "All Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: productService.getProductStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final products = snapshot.data ?? [];

                  final filtered = products.where((p) {
                    final nameMatch =
                        p['name']?.toString().toLowerCase().contains(
                          searchController.text.toLowerCase(),
                        ) ??
                        false;
                    final brandMatch =
                        brandController.text.isEmpty ||
                        (p['brand']?.toLowerCase().contains(
                              brandController.text.toLowerCase(),
                            ) ??
                            false);
                    final modelMatch =
                        modelController.text.isEmpty ||
                        (p['model']?.toLowerCase().contains(
                              modelController.text.toLowerCase(),
                            ) ??
                            false);
                    final yearMatch =
                        yearController.text.isEmpty ||
                        (p['year']?.toString() == yearController.text.trim());
                    return nameMatch && brandMatch && modelMatch && yearMatch;
                  }).toList();

                  if (filtered.isEmpty)
                    return const Center(child: Text("No products found."));

                  return GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 360,
                        ),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isSold = p['isSold'] == true;

                      return FutureBuilder<bool>(
                        future: productService.isFavorite(
                          currentUser!.uid,
                          p['id'],
                        ),
                        builder: (context, snapshot) {
                          final isFav = snapshot.data ?? false;

                          return Opacity(
                            opacity: isSold ? 0.5 : 1.0,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: CachedNetworkImage(
                                          imageUrl: p['image'],
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          p['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          p['desc'],
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          p['price'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: isSold
                                                  ? null
                                                  : () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ProductDetailScreen(
                                                                product: p,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.blue,
                                              ),
                                              child: const Text("View Details"),
                                            ),
                                            AnimatedScale(
                                              scale: 1.2,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  isFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFav
                                                      ? Colors.red
                                                      : null,
                                                ),
                                                onPressed: isSold
                                                    ? null
                                                    : () async {
                                                        if (p['id'] == null) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Invalid product.',
                                                              ),
                                                            ),
                                                          );
                                                          return;
                                                        }
                                                        if (isFav) {
                                                          await productService
                                                              .removeFromFavorites(
                                                                currentUser!
                                                                    .uid,
                                                                p['id'],
                                                              );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Removed ${p['name']} from favorites.',
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 1,
                                                                  ),
                                                            ),
                                                          );
                                                        } else {
                                                          await productService
                                                              .addToFavorites(
                                                                currentUser!
                                                                    .uid,
                                                                p,
                                                              );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Added ${p['name']} to favorites!',
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 1,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                        setState(() {});
                                                      },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSold
                                          ? Colors.red.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isSold
                                          ? "SOLD"
                                          : "${p['brand'] ?? 'N/A'} | ${p['year'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 30,
            child: FloatingActionButton.small(
              heroTag: 'fab_search',
              onPressed: _openSearchPopup,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.search),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 12,
            child: FloatingActionButton.extended(
              heroTag: 'fab_add_product',
              onPressed: () {
                if (isGuest) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Guest users cannot add listings. Please sign in.",
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddProductScreen()),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("New Listing"),
            ),
          ),
        ],
      ),
    );
  }
}
