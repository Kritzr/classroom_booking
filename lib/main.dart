import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  // FETCHING KEY SECURELY
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    //print("debug to check api key length : ${_apikey.length}");
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "You are a Class Booking Assistant. Convert user requests to JSON. "
              "Schema: {'field': string, 'value': string}. "
              "Fields: 'category' (Yoga, HIIT, Dance). "
              "If it's a greeting, return {'type': 'msg', 'content': 'Hi! Which class can I find for you?'}"
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
      // 1. Call the model and handle the response
      final response = await _model.generateContent([Content.text(text)]);

      // 2. Safely extract and clean the text response
      final String? rawText = response.text;
      if (rawText == null || rawText.isEmpty) {
        throw Exception("The AI returned an empty response.");
      }

      // 3. Remove Markdown JSON wrapping if present
      String cleanedJson = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // 4. Decode the cleaned JSON string
      final Map<String, dynamic> jsonResponse = jsonDecode(cleanedJson);

      if (jsonResponse['type'] == 'msg') {
        _addBotResponse(jsonResponse['content']);
      } else {
        // 5. Query Firebase Firestore
        final results = await FirebaseFirestore.instance
            .collection('classes')
            .where(jsonResponse['field'], isEqualTo: jsonResponse['value'])
            .get();

        if (results.docs.isEmpty) {
          _addBotResponse("I found no ${jsonResponse['value']} classes for you.");
        } else {
          String list = "I found these classes:\n";
          for (var doc in results.docs) {
            // Access fields safely
            final name = doc.data().containsKey('name') ? doc['name'] : 'Unnamed Class';
            final slots = doc.data().containsKey('slots') ? doc['slots'] : 0;
            list += "• $name ($slots slots left)\n";
          }
          _addBotResponse(list);
        }
      }
    } catch (e) {
      // 6. Print the ACTUAL error to the console for debugging
      debugPrint("Chatbot Error: $e");
      _addBotResponse("Error: ${e.toString()}");
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
      appBar: AppBar(title: const Text("AI Class Finder"), centerTitle: true),
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
          color: isUser ? Colors.indigo : Colors.grey[300],
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