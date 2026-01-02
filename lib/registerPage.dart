import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signInWithGoogle.dart';
import 'loginPage.dart';



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
  final GoogleAuthService _googleAuthService = GoogleAuthService();




  bool _isUsernameValid = true;



  Future<void> _handleGoogleSignup() async {
  try {
    User? user = await _googleAuthService.signInWithGoogle();
    if (user == null) return;

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await docRef.get();

    // If Firestore profile doesn't exist → create it
    if (!doc.exists) {
      await docRef.set({
        'firstName': user.displayName?.split(" ").first ?? '',
        'lastName': user.displayName?.split(" ").skip(1).join(" "),
        'email': user.email,
        'username': user.email?.split("@").first,
        'userType': 'user', // default for Google signup
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google sign up successful")),
    );

    Navigator.push
    (context,
      MaterialPageRoute(
        builder: (context) =>
        const LoginPage(),
      ),
    ); // back to login / home
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google signup failed")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF6F6F6),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Yellow Header
            Container(
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800), //350 for mobile,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        const Text(
                          "Join Us",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Create Free Account",
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 40),

                        // Register Card
                        Container(
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
                                  _isUsernameValid
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _isUsernameValid
                                      ? Colors.green
                                      : Colors.red,
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
                                          // 1️⃣ Create user in Firebase Auth
                                          UserCredential credential =
                                              await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                            email: email,
                                            password: password,
                                          );

                                          User user = credential.user!;

                                          // 2️⃣ Store additional data in Firestore
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .set({
                                            'firstName': firstName,
                                            'lastName': lastName,
                                            'username': username,
                                            'email': email,
                                            'userType': _selectedUserType,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });

                                          // 3️⃣ Navigate back or to home
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
                                    backgroundColor:
                                        const Color(0xFFFFC107),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
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

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  icon: Image.asset(
                                    "asset/google.png", // optional icon
                                    height: 20,
                                  ),
                                  label: const Text(
                                    "Sign up with Google",
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
                                  onPressed: _handleGoogleSignup,
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
                                    style:
                                        TextStyle(color: Colors.grey),
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
            ),
          ],
        ),
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
