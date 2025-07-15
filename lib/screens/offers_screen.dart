import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  void _updateOfferStatus(String offerId, String status) async {
    await FirebaseFirestore.instance.collection('offers').doc(offerId).update({
      'status': status,
    });
  }

  void _startChat(
    BuildContext context,
    String receiverId,
    String receiverName,
    String productId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: receiverId,
          receiverName: receiverName,
          productId: productId,
        ),
      ),
    );
  }

  Widget buildOfferCard({
    required Map<String, dynamic> data,
    required bool isSentTab,
    required VoidCallback? onAccept,
    required VoidCallback? onReject,
    required VoidCallback onChat,
  }) {
    final status = data['status']?.toString() ?? 'pending';
    final productTitle = data['productTitle'] ?? 'Product';
    final price = data['priceOffered'] ?? '0';
    final name = isSentTab
        ? data['sellerName'] ?? 'Seller'
        : data['buyerName'] ?? 'Buyer';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Offer: \$$price"),
            Text(isSentTab ? "To: $name" : "From: $name"),
            Text("Status: ${status[0].toUpperCase()}${status.substring(1)}"),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                if (!isSentTab)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    onPressed: status == 'pending' ? onAccept : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (!isSentTab)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    onPressed: status == 'pending' ? onReject : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: Text("Chat with ${isSentTab ? 'Seller' : 'Buyer'}"),
                  onPressed: onChat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Offers"),
          backgroundColor: const Color(0xFFFFF500),
          foregroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(text: "Received"),
              Tab(text: "Sent"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Received Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('sellerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text("No offers received"));

                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return buildOfferCard(
                      data: data,
                      isSentTab: false,
                      onAccept: () => _updateOfferStatus(doc.id, 'accepted'),
                      onReject: () => _updateOfferStatus(doc.id, 'rejected'),
                      onChat: () => _startChat(
                        context,
                        data['buyerId'],
                        data['buyerName'] ?? 'Buyer',
                        data['productId'],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Sent Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('buyerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text("No offers sent"));

                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return buildOfferCard(
                      data: data,
                      isSentTab: true,
                      onAccept: null,
                      onReject: null,
                      onChat: () => _startChat(
                        context,
                        data['sellerId'],
                        data['sellerName'] ?? 'Seller',
                        data['productId'],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
