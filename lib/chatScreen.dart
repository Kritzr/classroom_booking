import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



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

  @override
  void initState() {
    super.initState();
    //print("debug to check api key length : ${_apikey.length}");
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (_apiKey.isEmpty) {
      debugPrint("❌ Gemini API Key not loaded");
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system("""
              You are a Classroom Booking Assistant.

              You must respond ONLY in valid JSON.
              Use double quotes only.
              No explanations. No markdown.

              If the user asks about room availability, extract:
              - roomId
              - startTime (ISO format)
              - endTime (ISO format)

              Example output:
              {
                "roomId": "/rooms/CSE-AI",
                "startTime": "2025-12-29T12:30:00",
                "endTime": "2025-12-29T13:00:00"
              }

              If the input is unclear:
              {"type":"msg","content":"Please specify room and time."}
              """
      ),
    );
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
      final response = await _model.generateContent([Content.text(text)]);
      final String? rawText = response.text;

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
        // Perform the Firebase Query
        final results = await FirebaseFirestore.instance
            .collection('classes')
            .where(jsonResponse['field'], isEqualTo: jsonResponse['value'])
            .get();

        if (results.docs.isEmpty) {
          _addBotResponse("I found no ${jsonResponse['value']} classes for you.");
        } else {
          String list = "I found these classes:\n";
          for (var doc in results.docs) {
            final data = doc.data();
            final name = data['name'] ?? 'Unnamed Class';
            final slots = data['slots'] ?? 0;
            list += "• $name ($slots slots left)\n";
          }
          _addBotResponse(list);
        }
      }
    } catch (e) {
      // 6. Debugging output for the terminal
      debugPrint("Chatbot Error: $e");
      _addBotResponse("Sorry, I had trouble processing that. Try asking for a specific class category.");
    } finally {
      setState(() => _isTyping = false);
    }
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