import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> toggleBan(String uid, bool ban) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'banned': ban,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs;
          if (docs == null || docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userDoc = docs[index];
              final data = userDoc.data();

              if (data == null) return const SizedBox();

              final uid = userDoc.id;
              final name =
                  (data['firstName']?.toString().trim().isNotEmpty ?? false)
                  ? data['firstName'].toString()
                  : (data['name']?.toString().trim().isNotEmpty ?? false)
                  ? data['name'].toString()
                  : 'Unnamed';
              final email = data['email']?.toString() ?? 'No email';
              final isBanned = (data['banned'] ?? false) == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBanned ? Colors.green : Colors.red,
                      ),
                      onPressed: () => toggleBan(uid, !isBanned),
                      child: Text(isBanned ? 'Unban' : 'Ban'),
                    ),
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
