import 'package:flutter/material.dart';
import 'classroom_view.dart';
import 'permission_letter_page.dart';

class BookingDetailsPage extends StatelessWidget {
  final Room room;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String type;

  const BookingDetailsPage({
    super.key,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  String _formatTime(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Booking Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: primaryOrange,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Room: ${room.name}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryOrange,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Time: ${_formatTime(startTime)} - ${_formatTime(endTime)}",
              style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 16),
            Text(
              "Type: $type",
              style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Here you can add logic to confirm the booking
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Booking confirmed!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PermissionLetterPage(
                        initialEventTime:
                            "${_formatTime(startTime)} - ${_formatTime(endTime)}",
                        initialEventVenue: room.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
