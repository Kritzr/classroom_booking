import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;


const Color yellowMe = Color(0xFFFFC107);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  late final String _apiKey;
  // FETCHING KEY SECURELY
  late final GenerativeModel _model;

  DateTime _parseDateAndTime(String date, String time) {
    final d = date.split('-').map(int.parse).toList(); // [YYYY, MM, DD]
    final t = time.split(':').map(int.parse).toList(); // [HH, mm]
    return DateTime(d[0], d[1], d[2], t[0], t[1]);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
 }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isTyping = true;
    });
    _controller.clear();

    try {
      // 1. Get response from Gemini
      final response = await http.post(
        Uri.parse("https://chatwithgemini-clren2q6uq-uc.a.run.app"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text}),
      );

      final rawText = jsonDecode(response.body)['text'];

      if (rawText == null || rawText.isEmpty) {
        throw Exception("The AI returned an empty response.");
      }

      // 2. Clean Markdown and whitespace
      String cleanedJson = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

    cleanedJson = cleanedJson.replaceAllMapped(
      RegExp(r"'([^']*)'"),
      (match) => '"${match.group(1)}"',
    );

      // 3. Decode as dynamic to prevent Type Errors
      final dynamic decoded = jsonDecode(cleanedJson);
      Map<String, dynamic> jsonResponse;

      // 4. Fix: Check if it's a List or a Map
      if (decoded is List) {
        if (decoded.isNotEmpty && decoded.first is Map) {
          jsonResponse = Map<String, dynamic>.from(decoded.first);
        } else {
          throw Exception("AI returned a list but no valid query found.");
        }
      } else if (decoded is Map) {
        jsonResponse = Map<String, dynamic>.from(decoded);
      } else {
        throw Exception("Unexpected response format.");
      }

      // 5. Logic: Handle Message or Database Query
      if (jsonResponse['type'] == 'msg') {
        _addBotResponse(jsonResponse['content'] ?? "How can I help you today?");
      } else {
  // 🔍 Extract values from Gemini JSON
        final DocumentReference roomRef = FirebaseFirestore.instance.doc(jsonResponse['roomId']);
        final String date = jsonResponse['date'];       // "2025-12-29"
        final String start = jsonResponse['start'];     // "12:30"
        final String end = jsonResponse['end'];         // "13:00"

        final DateTime startTime = _parseDateAndTime(date, start);
        final DateTime endTime = _parseDateAndTime(date, end);

        final bool available = await isRoomAvailable(
          roomRef: roomRef,
          startTime: startTime,
          endTime: endTime,
        );

        if (available) {
          _addBotResponse(
            "The room is available from "
            "${_formatTime(startTime)} to ${_formatTime(endTime)}."
          );
        } else {
          _addBotResponse(
            "Sorry, the room is already booked for that time slot."
          );
        }
      }
    } catch (e, stack) {
       debugPrint("❌ REAL ERROR: $e");
       debugPrint("📍 STACK TRACE:\n$stack");
       _addBotResponse("Something went wrong. Please try again.");
    } finally {
      setState(() => _isTyping = false);
    }
  }

  Future<bool> isRoomAvailable({
    required DocumentReference roomRef,
    required DateTime startTime,
    required DateTime endTime,
  }) async {

    final query = await FirebaseFirestore.instance
        .collection('slots')
        .where('roomId', isEqualTo: roomRef)
        .where('status', isEqualTo: 'booked')
        .where('startTime', isLessThan: Timestamp.fromDate(endTime))
        .where('endTime', isGreaterThan: Timestamp.fromDate(startTime))
        .get();

    // If any overlapping slot exists → NOT available
    return query.docs.isEmpty;
  }


  void _addBotResponse(String text) {
    setState(() => _messages.add({"text": text, "isUser": false}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Class Finder"), 
        centerTitle: true,
        backgroundColor: yellowMe,
        ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _ChatBubble(
                text: _messages[i]['text'],
                isUser: _messages[i]['isUser'],
              ),
            ),
          ),
          if (_isTyping) const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("AI is searching...", style: TextStyle(fontStyle: FontStyle.italic)),
          ),
          _InputArea(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isUser ? yellowMe : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black)),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  const _InputArea({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Search for a class...", border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: () => onSend(controller.text)),
        ],
      ),
    );
  }
}