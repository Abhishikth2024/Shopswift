import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportedUsersScreen extends StatelessWidget {
  const ReportedUsersScreen({super.key});

  Stream<QuerySnapshot> getReports() {
    return FirebaseFirestore.instance.collection('reports').snapshots();
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reported Users"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final reports = snapshot.data!.docs;

          if (reports.isEmpty)
            return const Center(child: Text("No reports found."));

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index].data() as Map<String, dynamic>;
              final reportedUserId = report['reportedUserId'] ?? 'N/A';
              final reportedBy = report['reportedBy'] ?? 'N/A';
              final reason = report['reason'] ?? 'No reason';

              return FutureBuilder<Map<String, dynamic>?>(
                future: getUser(reportedUserId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        userData != null
                            ? userData['name'] ?? 'Unknown'
                            : reportedUserId,
                      ),
                      subtitle: Text(
                        "Reported by: $reportedBy\nReason: $reason",
                      ),
                      trailing: const Icon(Icons.report, color: Colors.red),
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
