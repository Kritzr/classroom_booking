import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PermissionLetterPage extends StatefulWidget {
    final String? initialEventTime;
  const PermissionLetterPage({super.key, this.initialEventTime});

  @override
  State<PermissionLetterPage> createState() => _PermissionLetterPageState();
}

class _PermissionLetterPageState extends State<PermissionLetterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final clubName = TextEditingController();
  final chairpersonName = TextEditingController();
  final staffName = TextEditingController();
  final deanName = TextEditingController();
  final department = TextEditingController();
  final eventName = TextEditingController();
  final eventDate = TextEditingController();
  final eventTime = TextEditingController();
  final eventReason = TextEditingController();
  final eventVenue = TextEditingController();

  // Signature Controllers
  final SignatureController chairSign = SignatureController();
  final SignatureController staffSign = SignatureController();

  bool showPreview = false;
   @override
  void initState() {
    super.initState();
    // Pre-fill eventTime if provided
    if (widget.initialEventTime != null) {
      eventTime.text = widget.initialEventTime!;
    }
  }
  @override
  void dispose() {
    chairSign.dispose();
    staffSign.dispose();
    super.dispose();
  }

Widget inputField( String label,TextEditingController controller, {int lines = 1,}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      textInputAction:
          lines > 1 ? TextInputAction.newline : TextInputAction.next,
      keyboardType:
          lines > 1 ? TextInputType.multiline : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    ),
  );
}


  Widget signaturePad(String title, SignatureController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: Signature(
            controller: controller,
            height: 150,
            backgroundColor: Colors.grey[200]!,
          ),
        ),
        TextButton(
          onPressed: () => controller.clear(),
          child: const Text("Clear Signature"),
        ),
      ],
    );
  }

  Widget letterPreview() {
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
        ${clubName.text},
        Madras Institute of Technology,
        Chromepet, Chennai – 600044

        To:
        The Dean,
        Madras Institute of Technology,
        Chromepet, Chennai – 600044

        Date: ${eventDate.text}

        Subject: Permission Request for Conducting ${eventName.text}

        Respected Sir/Madam,

        We, the members of the ${clubName.text}, kindly request permission to organize the event
        "${eventName.text}" on ${eventDate.text} at ${eventTime.text}.

        The event is ${eventReason.text}.

        We assure that the event will be conducted following all institutional rules.

        Thanking you.

        Yours sincerely,
        ${chairpersonName.text}
        Chairperson – ${clubName.text}
                """,
      ),
    );
  }

//storing letter to firestore

Future<void> submitLetterToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User not logged in")),
    );
    return;
  }

  await FirebaseFirestore.instance.collection('event_letters').add({
    'clubName': clubName.text.trim(),
    'chairpersonName': chairpersonName.text.trim(),
    'staffInchargeName': staffName.text.trim(),
    'eventName': eventName.text.trim(),
    'eventDate': eventDate.text.trim(),
    'eventVenue': eventVenue.text.trim(),
    'eventReason': eventReason.text.trim(),
    'eventTime' : eventTime.text.trim(),
    'userEmail' : user.email,
    'status': 'submitted',
    'approvalStatus': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'userId': user.uid,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Letter submitted successfully")),
  );

  Navigator.pop(context); // optional: go back after submit
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(title: const Text("Permission Letter")),
    body : SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("📌 Letter Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              inputField("Club Name", clubName),
              inputField("Chairperson Name", chairpersonName),
              inputField("Staff In-Charge Name", staffName),
              inputField("Event Name", eventName),
              inputField("Event Date", eventDate),
              inputField('Event Time', eventTime),
              inputField("Event Venue", eventVenue),
              inputField("Event Reason", eventReason, lines: 4),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() => showPreview = true);
                  }
                },
                child: const Text("Generate Letter Preview"),
              ),

              const SizedBox(height: 20),

              if (showPreview) ...[
                const Text("📄 Letter Preview",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                letterPreview(),

                const SizedBox(height: 30),

                const Text("✍️ E-Signatures",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                signaturePad("Chairperson Signature", chairSign),
                const SizedBox(height: 20),
                signaturePad("Staff In-Charge Signature", staffSign),
                const SizedBox(height: 20),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await submitLetterToFirestore();
                    },
                    child: const Text(
                      "Submit Letter",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              ],
            ],
          ),
        ),
      ),
  );
}
}
