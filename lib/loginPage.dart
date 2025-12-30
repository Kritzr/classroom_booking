import 'dart:math';
import 'package:flutter/material.dart';
import 'registerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signInWithGoogle.dart';
import 'home_page.dart';

import 'adminDashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleAuthService _authService = GoogleAuthService();
  bool _savePassword = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF6F6F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // Yellow Background
                  Container(
                    height: height * 0.45,
                    width: width,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Content
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          children: [
                            SizedBox(height: height * 0.12),

                            // Header Text
                            const Text(
                              "Hello",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(fontSize: 16),
                            ),

                            SizedBox(height: height * 0.05),

                            // Login Card
                            Container(
                              width: width * 0.9,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Login Account",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Email
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: "Email Address",
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Password
                                  TextField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Save Password + Forgot
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _savePassword,
                                        activeColor: Colors.green,
                                        onChanged: (value) {
                                          setState(() {
                                            _savePassword = value!;
                                          });
                                        },
                                      ),
                                      const Text("Save Password"),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          // Implement forgot password logic here
                                        },
                                        child: const Text("Forgot Password?"),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final email = _emailController.text
                                            .trim();
                                        final password = _passwordController
                                            .text
                                            .trim();

                                        if (email.isEmpty || password.isEmpty) {
                                          _showDialog(
                                            title: 'Error',
                                            message:
                                                'Please enter email and password.',
                                          );
                                          return;
                                        }

                                        try {
                                          UserCredential credential =
                                              await FirebaseAuth.instance
                                                  .signInWithEmailAndPassword(
                                                    email: email,
                                                    password: password,
                                                  );

                                          User user = credential.user!;

                                          DocumentSnapshot userDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .get();

                                          if (!userDoc.exists) {
                                            _showDialog(
                                              title: "Error",
                                              message:
                                                  "User data not found. Please contact support.",
                                            );
                                            return;
                                          }

                                          String userType = userDoc['userType'];

                                          if (!mounted) return;

                                          if (userType == 'admin') {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const AdminDashboard(),
                                              ),
                                            );
                                          } else {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const HomePage(),
                                              ),
                                            );
                                          }
                                        } on FirebaseAuthException catch (e) {
                                          if (e.code == 'user-not-found') {
                                            _showDialog(
                                              title: "Account Not Found",
                                              message:
                                                  "No account found. Please create an account!",
                                            );
                                          } else if (e.code ==
                                              'wrong-password') {
                                            _showDialog(
                                              title: "Wrong Password",
                                              message:
                                                  "The password you entered is incorrect.",
                                            );
                                          } else {
                                            _showDialog(
                                              title: "Login Failed",
                                              message:
                                                  e.message ??
                                                  "Something went wrong",
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFC107,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Login Account",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // Google Sign-In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        User? user = await _authService
                                            .signInWithGoogle();
                                        if (!mounted) return;

                                        if (user != null) {
                                          DocumentSnapshot userDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .get();

                                          if (!userDoc.exists) {
                                            _showDialog(
                                              title: "Profile Missing",
                                              message:
                                                  "Please complete registration.",
                                            );
                                            return;
                                          }

                                          String userType = userDoc['userType'];

                                          if (!mounted) return;

                                          if (userType == 'admin') {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const AdminDashboard(),
                                              ),
                                            );
                                          } else {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const HomePage(),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFC107,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // Create Account
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Create New Account",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
