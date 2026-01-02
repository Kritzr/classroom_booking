import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLetterReviewPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> letterData;

  const AdminLetterReviewPage({
    super.key,
    required this.docId,
    required this.letterData,
  });

  @override
  State<AdminLetterReviewPage> createState() =>
      _AdminLetterReviewPageState();
}

class _AdminLetterReviewPageState extends State<AdminLetterReviewPage> {
  final SignatureController _adminSignController =
      SignatureController(penStrokeWidth: 3);

  @override
  void dispose() {
    _adminSignController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('event_letters')
        .doc(widget.docId)
        .update({
      'approvalStatus': status,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user?.email,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Letter $status")),
    );

    Navigator.pop(context);
  }

  @override
  Widget letterPreview(Map<String, dynamic> data) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(),
      color: Colors.grey[50],
    ),
    child: SelectableText(
      """
    From:
    The Chairperson,
    ${data['clubName']},
    Madras Institute of Technology,
    Chromepet, Chennai – 600044

    To:
    The ${data['deanName']},
    Madras Institute of Technology,
    Chromepet, Chennai – 600044

    Date: ${data['eventDate']}

    Subject: Permission Request for Conducting ${data['eventName']}

    Respected Sir/Madam,

    We, the members of the ${data['clubName']}, kindly request permission to organize the event
    "${data['eventName']}" on ${data['eventDate']} at ${data['eventTime']}.

    The event is ${data['eventReason']}.

    We assure that the event will be conducted following all institutional rules.

    Thanking you.

    Yours sincerely,
    ${data['chairpersonName']}
    Chairperson – ${data['clubName']}
          """,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
  );
}

  Widget build(BuildContext context) {
    final data = widget.letterData;

    return Scaffold(
      appBar: AppBar(title: const Text("Review Letter")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📄 Letter Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: letterPreview(widget.letterData),

            ),

            const SizedBox(height: 24),

            // ✍️ Admin Signature
            const Text(
              "Admin Signature",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Signature(
                controller: _adminSignController,
                backgroundColor: Colors.grey[200]!,
              ),
            ),

            TextButton(
              onPressed: () => _adminSignController.clear(),
              child: const Text("Clear Signature"),
            ),

            const SizedBox(height: 24),

            // ✅ Approve / ❌ Reject Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _updateStatus("approved"),
                    child: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _updateStatus("rejected"),
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
