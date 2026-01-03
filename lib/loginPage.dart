import 'dart:math';
import 'package:flutter/material.dart';
import 'registerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signInWithGoogle.dart';
import 'home_page.dart';
import 'permission_letter_page.dart';
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
              FocusScope.of(context).unfocus(); // 👈 releases focus
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
                      constraints: const BoxConstraints(
                        maxWidth: 700, // 👈 important
                      ),
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
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
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
                                    prefixIcon: const Icon(Icons.lock_outline),
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
                                        _showForgotPasswordDialog();    
                                      },
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final email = _emailController.text.trim();
                                      final password = _passwordController.text.trim();

                                      if (email.isEmpty || password.isEmpty) {
                                        _showDialog(
                                          title: "Missing Details",
                                          message: "Please enter email and password",
                                        );
                                        return;
                                      }

                                      try {
                                        // 🔐 Try signing in user
                                        UserCredential credential =
                                            await FirebaseAuth.instance.signInWithEmailAndPassword(
                                          email: email,
                                          password: password,
                                        );

                                        User user = credential.user!;

                                        // 🔹 Fetch user data from Firestore
                                        DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .get();

                                        if (!userDoc.exists) {
                                          _showDialog(
                                            title: "Error",
                                            message: "User data not found. Please contact support.",
                                          );
                                          return;
                                        }

                                        String userType = userDoc['userType']; // "admin" or "user"

                                        if (!mounted) return;

                                        // 🔹 Navigate based on role
                                        if (userType == 'admin') {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AdminDashboard(),
                                            ),
                                          );
                                        } else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const HomePage(),
                                            ),
                                          );
                                        } 
                                      } on FirebaseAuthException catch (e) {
                                        if (e.code == 'user-not-found') {
                                          // 👇 User does not exist → show Create Account dialog
                                          _showDialog(
                                            title: "Account Not Found",
                                            message: "No account found. Please create an account!",
                                          );
                                        } else if (e.code == 'wrong-password') {
                                          _showDialog(
                                            title: "Wrong Password",
                                            message: "The password you entered is incorrect.",
                                          );
                                        } else {
                                          _showDialog(
                                            title: "Login Failed",
                                            message: e.message ?? "Something went wrong",
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFC107),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
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

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                    child: OutlinedButton.icon(
                                      icon: Image.asset(
                                        "asset/google.png", // optional icon
                                        height: 20,
                                      ),
                                      label: const Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor:  Colors.white,
                                        side: const BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      onPressed: () async {
                                      User? user =
                                          await _authService.signInWithGoogle();
                                      // If sign-in is successful, show a dialog and navigate to the HomeScreen
                                      if (!mounted) return;
                                      
                                      if (user != null) {
                                        DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .get();

                                        if (!userDoc.exists) {
                                          _showDialog(
                                            title: "Profile Missing",
                                            message: "Please complete registration.",
                                          );
                                          return;
                                        }

                                        String userType = userDoc['userType'];

                                        if (!mounted) return;

                                        Navigator.of(context).pop(); // close dialog

                                        if (userType == 'admin') {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AdminDashboard()),
                                          );
                                        } else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const HomePage()),
                                          );
                                        }
                                      }
                                    },
                                    ),
                                  
                                ),

                                const SizedBox(height: 15),

                                // Create Account
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
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
          ), // stack expand
          );
        },
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: "Enter your registered email",
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (email.isEmpty) {
                _showDialog(
                  title: "Missing Email",
                  message: "Please enter your email address",
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!mounted) return;

                Navigator.pop(context);

                _showDialog(
                  title: "Email Sent",
                  message: "A password reset link has been sent to your email.",
                );
              } on FirebaseAuthException catch (e) {
                _showDialog(
                  title: "Error",
                  message: e.message ?? "Something went wrong",
                );
              }
            },
            child: const Text("Send Reset Link"),
          ),
        ],
      ),
    );
  }

  void _showDialog({ required String title, required String message,}) {
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
