import 'package:classroom_app/adminDashboard.dart';
import 'package:classroom_app/home_page.dart';
import 'package:classroom_app/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = 'user'; // default
  bool _isUsernameValid = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                    height: size.height * 0.45,
                    width: size.width,
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
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 700,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.12),

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
                              "Create Account",
                              style: TextStyle(fontSize: 16),
                            ),

                            SizedBox(height: size.height * 0.05),

                            // Register Card
                            Container(
                              width: size.width * 0.9,
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
                                    "Personal Info",
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

                                  const Text("Your Name"),
                                  const SizedBox(height: 8),

                                  // First + Last Name
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _inputField(
                                          controller: _firstNameController,
                                          hint: "First Name",
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _inputField(
                                          controller: _lastNameController,
                                          hint: "Last Name",
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 15),
                                  const Text("Email Address"),
                                  const SizedBox(height: 8),

                                  _inputField(
                                    controller: _emailController,
                                    hint: "Your Email Address",
                                    icon: Icons.email_outlined,
                                  ),

                                  const SizedBox(height: 15),
                                  const Text("Username"),
                                  const SizedBox(height: 8),

                                  _inputField(
                                    controller: _usernameController,
                                    hint: "example1234",
                                    suffix: Icon(
                                      _isUsernameValid ? Icons.check_circle : Icons.error,
                                      color: _isUsernameValid ? Colors.green : Colors.red,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _isUsernameValid = value.length >= 4;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 15),
                                  const Text("Password"),
                                  const SizedBox(height: 8),

                                  _inputField(
                                    controller: _passwordController,
                                    hint: "Enter Password",
                                    icon: Icons.lock_outline,
                                  ),

                                  const SizedBox(height: 15),
                                  const Text("User Type"),
                                  const SizedBox(height: 8),

                                  DropdownButtonFormField<String>(
                                    value: _selectedUserType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'user',
                                        child: Text("User"),
                                      ),
                                      DropdownMenuItem(
                                        value: 'admin',
                                        child: Text("Admin"),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUserType = value!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final firstName = _firstNameController.text.trim();
                                        final lastName = _lastNameController.text.trim();
                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text.trim();
                                        final username = _usernameController.text.trim();

                                        if (firstName.isEmpty ||
                                            lastName.isEmpty ||
                                            email.isEmpty ||
                                            password.isEmpty ||
                                            username.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Please fill all fields")),
                                          );
                                          return;
                                        }

                                        try {
                                          UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                            email: email,
                                            password: password,
                                          );

                                          User user = credential.user!;

                                          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                            'firstName': firstName,
                                            'lastName': lastName,
                                            'username': username,
                                            'email': email,
                                            'userType': _selectedUserType,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Account created successfully")),
                                          );

                                          Navigator.pop(context); // back to login
                                        } on FirebaseAuthException catch (e) {
                                          String message = "Registration failed";

                                          if (e.code == 'email-already-in-use') {
                                            message = "Email already registered";
                                          } else if (e.code == 'weak-password') {
                                            message = "Password should be at least 6 characters";
                                          } else if (e.code == 'invalid-email') {
                                            message = "Invalid email address";
                                          }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFC107),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Text(
                                        "Save & Continue",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Back to Login",
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
