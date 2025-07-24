import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_swift/services/notification_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'write_screen_review.dart';
import 'other_user_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _offerController = TextEditingController();
  double? selectedPercentage;
  final ChatService _chatService = ChatService();

  String sellerName = '';
  String sellerEmail = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSellerDetails();
    });
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  Future<void> fetchSellerDetails() async {
    final uid = widget.product['uid'];
    if (uid == null || uid.toString().isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          sellerName = data['name'] ?? 'Seller';
          sellerEmail = data['email'] ?? '';
        });
      }
    } catch (_) {}
  }

  double calculateOfferPrice(double price, double percent) {
    return (price * percent).roundToDouble();
  }

  void _showLoginPrompt() {
    Fluttertoast.showToast(
      msg: "You need to sign in to use this feature.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuest = currentUser == null || currentUser.isAnonymous;
    final sellerId = widget.product['uid'] ?? '';
    final isOwnProduct = currentUser?.uid == sellerId;
    final originalPrice =
        double.tryParse(
          product['price'].toString().replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                product['image'],
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['name'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product['price'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF28A745),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${product['brand'] ?? 'Brand'} • ${product['model'] ?? 'Model'} • ${product['year'] ?? 'Year'}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            if (sellerName.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (sellerId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OtherUserProfileScreen(userId: sellerId),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        widget.product['sellerImage'] ??
                            'https://ui-avatars.com/api/?name=$sellerName',
                      ),
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sellerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        if (sellerEmail.isNotEmpty)
                          Text(
                            sellerEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(sellerId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;

                  if (data == null) return const SizedBox.shrink();

                  final rating = (data['averageRating'] ?? 0).toStringAsFixed(
                    1,
                  );
                  final count = data['reviewCount'] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rating ⭐ ($count reviews)',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      if (!isOwnProduct)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Write a Review'),
                          onPressed: () {
                            if (isGuest) {
                              _showLoginPrompt();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WriteReviewScreen(targetUserId: sellerId),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.report),
                        label: const Text('Report User'),
                        onPressed: () {
                          if (isGuest) {
                            _showLoginPrompt();
                          } else {
                            _showReportDialog(
                              currentUser?.uid,
                              sellerId,
                              product['id'] ?? product['key'] ?? '',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(sellerId)
                    .collection('reviews')
                    .orderBy('timestamp', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final reviews = snapshot.data?.docs ?? [];

                  if (reviews.isEmpty) {
                    return const Text("No reviews yet.");
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Reviews:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...reviews.map((doc) {
                        final r = doc.data() as Map<String, dynamic>;
                        final name = r['reviewerName'] ?? 'User';
                        final comment = r['comment'] ?? '';
                        final rating = r['rating'] ?? 0;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(name[0])),
                          title: Text('$name • $rating ⭐'),
                          subtitle: Text(comment),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 20),
            const Text(
              "Description:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product['desc'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Enter Your Offer:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _offerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter amount manually",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<double>(
              value: selectedPercentage,
              decoration: const InputDecoration(
                labelText: "Or select offer percentage",
                border: OutlineInputBorder(),
              ),
              items: [1.0, 0.9, 0.8, 0.7].map((value) {
                final percent = (value * 100).toInt();
                final price = calculateOfferPrice(originalPrice, value);
                return DropdownMenuItem<double>(
                  value: value,
                  child: Text("$percent% of price (\$$price)"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPercentage = value;
                  if (value != null) {
                    _offerController.text = calculateOfferPrice(
                      originalPrice,
                      value,
                    ).toStringAsFixed(0);
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isGuest) {
                    _showLoginPrompt();
                    return;
                  }

                  final offerText = _offerController.text.trim();
                  final offerPrice = double.tryParse(offerText);
                  if (offerText.isEmpty || offerPrice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid offer amount.")),
                    );
                    return;
                  }

                  final productId =
                      widget.product['id'] ?? widget.product['key'] ?? '';
                  final buyerId = currentUser.uid;

                  await FirebaseFirestore.instance.collection('offers').add({
                    'productId': productId,
                    'productTitle': widget.product['name'] ?? '',
                    'buyerId': buyerId,
                    'buyerName': currentUser.displayName ?? 'Anonymous',
                    'sellerId': sellerId,
                    'priceOffered': offerPrice,
                    'message': '',
                    'status': 'pending',
                    'createdAt': Timestamp.now(),
                  });

                  await NotificationService.show(
                    'New Offer Received',
                    'You received an offer of \$$offerPrice for ${widget.product['name']}',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Offer of \$$offerPrice sent for ${widget.product['name']}!',
                      ),
                    ),
                  );

                  _offerController.clear();
                  setState(() {
                    selectedPercentage = null;
                  });
                },
                icon: const Icon(Icons.local_offer_outlined),
                label: const Text("Send Offer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF500),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!isOwnProduct && sellerId.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (isGuest) {
                      _showLoginPrompt();
                      return;
                    }

                    final buyerId = currentUser.uid;
                    final productId = product['id'] ?? product['key'] ?? '';

                    final chatId = _chatService.getChatId(
                      productId,
                      buyerId,
                      sellerId,
                    );
                    final chatRef = FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId);
                    final chatSnap = await chatRef.get();

                    if (!chatSnap.exists) {
                      await chatRef.set({
                        'participants': [buyerId, sellerId],
                        'productId': productId,
                        'lastMessage': '',
                        'lastUpdated': FieldValue.serverTimestamp(),
                        'unreadBy': [sellerId],
                      });
                    }

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: sellerId,
                          receiverName: sellerName,
                          productId: productId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat with Seller"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (isOwnProduct)
              const Text(
                "You posted this item.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(
    String? reporterId,
    String reportedUserId,
    String productId,
  ) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please describe the reason for reporting:"),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Enter your reason...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = _reasonController.text.trim();
              if (reason.isEmpty || reporterId == null) return;

              await FirebaseFirestore.instance.collection('reports').add({
                'reporterId': reporterId,
                'reportedUserId': reportedUserId,
                'reason': reason,
                'productId': productId,
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report submitted successfully.")),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
