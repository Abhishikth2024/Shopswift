import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_swift/screens/home_screen.dart';
import 'package:shop_swift/screens/profile_screen.dart';
import 'package:shop_swift/screens/login_screen.dart';
import 'package:shop_swift/services/auth_service.dart';
import 'package:shop_swift/screens/chat_list_screen.dart';
import 'package:shop_swift/screens/offers_screen.dart';
import 'package:shop_swift/screens/favorites_screen.dart';

class CustomNavDrawer extends StatelessWidget {
  final bool isGoogleSignIn;

  const CustomNavDrawer({super.key, required this.isGoogleSignIn});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF500),
      child: SafeArea(
        child: Column(
          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final currentUser = snapshot.data;
                final uid = currentUser?.uid ?? '';
                final isGuest = currentUser?.isAnonymous ?? true;

                if (currentUser == null) return const SizedBox();

                if (isGuest) {
                  return _buildGuestHeader(context);
                } else {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final userName = data?['name'] ?? 'User';
                      final userImage =
                          data?['profilePicUrl'] ?? 'assets/images/avatar.png';

                      return _buildUserHeader(
                        context,
                        userName,
                        userImage,
                        isGoogleSignIn,
                      );
                    },
                  );
                }
              },
            ),
            Expanded(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final uid = user?.uid ?? '';
                  final isGuest = user?.isAnonymous ?? true;

                  return ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home, color: Colors.black),
                        title: const Text('Home'),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.favorite,
                          color: Colors.black,
                        ),
                        title: Text(
                          isGuest
                              ? 'Favorites (Sign in required)'
                              : 'Favorites',
                        ),
                        onTap: () {
                          if (isGuest) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please sign in to view favorites.",
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      if (!isGuest)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .where('participants', arrayContains: uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();

                            final allChats = snapshot.data!.docs;
                            final unreadChats = allChats.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final List unreadBy = data['unreadBy'] ?? [];
                              return unreadBy.contains(uid);
                            }).toList();

                            final unreadCount = unreadChats.length;

                            return ListTile(
                              leading: const Icon(
                                Icons.chat,
                                color: Colors.black,
                              ),
                              title: Row(
                                children: [
                                  const Text('Chat'),
                                  if (unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "$unreadCount",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatListScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      if (!isGuest)
                        ListTile(
                          leading: const Icon(
                            Icons.local_offer_outlined,
                            color: Colors.black,
                          ),
                          title: const Text('Offers'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OffersScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Guest User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Log Out"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Log Out"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    String userName,
    String userImage,
    bool isGoogleSignIn,
  ) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(isGoogleSignIn: isGoogleSignIn),
                ),
              );
            },
            child: CircleAvatar(
              radius: 28,
              backgroundImage: userImage.startsWith('http')
                  ? NetworkImage(userImage)
                  : AssetImage(userImage) as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(isGoogleSignIn: isGoogleSignIn),
                  ),
                );
              },
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Log Out"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Log Out"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
