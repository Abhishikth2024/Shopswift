import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'write_screen_review.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  String name = '';
  String email = '';
  String profileImage = '';
  double averageRating = 0;
  int reviewCount = 0;
  int? filterByStars;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        email = data['email'] ?? '';
        profileImage = data['image'] ?? '';
        averageRating = (data['averageRating'] ?? 0).toDouble();
        reviewCount = (data['reviewCount'] ?? 0);
      });
    }
  }

  Stream<QuerySnapshot> _filteredReviews() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('reviews');

    if (filterByStars != null) {
      query = query.where('rating', isEqualTo: filterByStars!.toDouble());
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : NetworkImage('https://ui-avatars.com/api/?name=$name'),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '$averageRating ⭐ ($reviewCount reviews)',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (currentUser != null && currentUser.uid != widget.userId)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WriteReviewScreen(targetUserId: widget.userId),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text("Write a Review"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Filter by rating: '),
                DropdownButton<int>(
                  value: filterByStars,
                  hint: const Text("All"),
                  items: [null, 5, 4, 3, 2, 1].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value == null ? "All" : "$value ⭐"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => filterByStars = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filteredReviews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data?.docs ?? [];

                if (reviews.isEmpty) {
                  return const Center(child: Text("No reviews available."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index].data() as Map<String, dynamic>;
                    final reviewer = r['reviewerName'] ?? 'User';
                    final rating = r['rating']?.toString() ?? '0';
                    final comment = r['comment'] ?? '';
                    final date = (r['timestamp'] as Timestamp?)?.toDate();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(reviewer[0])),
                        title: Text('$reviewer • $rating ⭐'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment),
                            if (date != null)
                              Text(
                                date.toLocal().toString().split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
