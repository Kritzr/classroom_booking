import 'package:classroom_booking/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'permission_letter_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:classroom_booking/adminDashboard.dart';
import 'package:classroom_booking/loginPage.dart';
import 'home_page.dart';
import 'chatScreen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


const Color primaryOrange = Color(0xFFE2852E);
const Color softYellow = Color(0xFFF5C857);
const Color paleYellow = Color(0xFFFFEE91);


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try{
    if(Firebase.apps.isEmpty){
      await Firebase.initializeApp(
        options : DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    }
    else{
      Firebase.app(); // if already initialized, use that one
      print('Firebase already initialized');
    }
  }
  catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduBook',
      theme: ThemeData(
        //scaffoldBackgroundColor: paleYellow.withOpacity(0.25),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Use FirebaseAuth to check user
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        // Fetch user type from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data != null && data['userType'] == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
