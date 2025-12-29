import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'letterReceived.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Pending Letters"),
            _letterSection(context, 'pending'),

            const SizedBox(height: 24),

            _sectionTitle("Accepted Letters"),
            _letterSection(context, 'approved'),

            const SizedBox(height: 24),

            _sectionTitle("Rejected Letters"),
            _letterSection(context, 'rejected'),
          ],
        ),
      ),
    );
  }

  // ---------- Section Title ----------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------- Firestore Section ----------
  Widget _letterSection(BuildContext context, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('event_letters')
          .where('approvalStatus', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              status == 'pending'
                  ? "No pending letters"
                  : status == 'approved'
                      ? "No accepted letters"
                      : "No rejected letters",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final letters = snapshot.data!.docs;

        return Column(
          children: letters.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  data['eventName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Club: ${data['clubName']}"),
                    const SizedBox(height: 4),
                    Text(
                      data['eventReason'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminLetterReviewPage(
                        docId: doc.id,
                        letterData: data,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
