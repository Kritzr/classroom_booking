import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'firestore_service.dart';

const Color yellow = Color(0xFFFFC107);

class PermissionLetterPage extends StatefulWidget {
  final String? initialEventTime;
  final String? initialEventVenue;
  final Room room;
  final String type;
  const PermissionLetterPage({
    super.key,
    this.initialEventTime,
    this.initialEventVenue,
    required this.room,
    required this.type,
  });

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
  final userEmail = TextEditingController();

  // Signature Controllers
  final SignatureController chairSign = SignatureController();
  final SignatureController staffSign = SignatureController();

  bool showPreview = false;

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length != 2) throw FormatException('Invalid time format');
    final timePart = parts[0];
    final ampm = parts[1].toUpperCase();
    final timeParts = timePart.split(':');
    if (timeParts.length != 2) throw FormatException('Invalid time format');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill eventTime if provided
    if (widget.initialEventTime != null) {
      eventTime.text = widget.initialEventTime!;
    }

    // Pre-fill eventVenue if provided
    if (widget.initialEventVenue != null) {
      eventVenue.text = widget.initialEventVenue!;
    }
  }

  @override
  void dispose() {
    chairSign.dispose();
    staffSign.dispose();
    super.dispose();
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        textInputAction: lines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        keyboardType: lines > 1 ? TextInputType.multiline : TextInputType.text,
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
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
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
      decoration: BoxDecoration(border: Border.all(), color: Colors.grey[50]),
      child: SelectableText("""
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
                """),
    );
  }

  //storing letter to firestore

  Future<void> submitLetterToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
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
      'eventTime': eventTime.text.trim(),
      'userEmail': userEmail.text.trim(),
      'status': 'submitted',
      'approvalStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
    });

    // Create the booking as reserved
    try {
      DateTime eventDateParsed = DateTime.parse(eventDate.text.trim());
      final timeParts = eventTime.text.split(' - ');
      if (timeParts.length != 2) throw FormatException('Invalid time range');
      TimeOfDay startTimeOfDay = _parseTime(timeParts[0]);
      TimeOfDay endTimeOfDay = _parseTime(timeParts[1]);
      DateTime startTime = DateTime(
        eventDateParsed.year,
        eventDateParsed.month,
        eventDateParsed.day,
        startTimeOfDay.hour,
        startTimeOfDay.minute,
      );
      DateTime endTime = DateTime(
        eventDateParsed.year,
        eventDateParsed.month,
        eventDateParsed.day,
        endTimeOfDay.hour,
        endTimeOfDay.minute,
      );
      await FirestoreService().addBooking(
        user.uid,
        widget.room.id,
        startTime,
        endTime,
        widget.type,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Letter submitted but error creating booking: $e"),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Permission letter submitted and booking reserved pending approval",
        ),
      ),
    );

    Navigator.pop(context); // optional: go back after submit
  }
  Widget datePickerField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      readOnly: true, // Prevent manual input
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000), // Earliest date
          lastDate: DateTime(2100), // Latest date
        );
        if (pickedDate != null) {
          // Format the date as YYYY-MM-DD
          controller.text = "${pickedDate.toLocal()}".split(' ')[0];
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Permission Letter"),
        backgroundColor: yellow,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Letter Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              inputField("Club Name", clubName),
              inputField("Chairperson Name", chairpersonName),
              inputField("Staff In-Charge Name", staffName),
              inputField("Club Mail ID", userEmail),
              inputField("Event Name", eventName),
              datePickerField("Event Date", eventDate),
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
                const Text(
                  "📄 Letter Preview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                letterPreview(),
                const SizedBox(height: 30),
                const Text(
                  "✍️ E-Signatures",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
