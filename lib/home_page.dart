import 'package:classroom_app/loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'classroom_view.dart';
import 'firestore_service.dart';
import 'models.dart';

/* -------------------- THEME COLORS -------------------- */
const Color primaryOrange = Color(0xFFE2852E);
const Color softYellow = Color(0xFFF5C857);
const Color paleYellow = Color(0xFFFFEE91);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestore = FirestoreService();
  UserModel? currentUser;
  List<Booking> bookings = [];
  List<Department> departments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadData();
  }

  void _checkConnection() async {
    final firestoreService = FirestoreService();
    bool connected = await firestoreService.testConnection();
    if (connected) {
      print('Database connected successfully');
      // Show success message or proceed
    } else {
      print('Database connection failed');
      // Show error message or retry
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await _firestore.getCurrentUser();
      print(user?.id);
      if (user != null) {
        print(user.firstname);
        final userBookings = await _firestore.getBookingsForUser(user.id);
      
        print(user.firstname);
        final depts = await _firestore.getDepartments();
        setState(() {
          currentUser = user;
          bookings = userBookings;
          departments = depts;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "EduBook",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: primaryOrange,
        elevation: 4,
        shadowColor: primaryOrange.withOpacity(0.5),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryOrange, softYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${currentUser?.firstname ?? 'User'}!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Manage your classroom bookings effortlessly.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),

            // About Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About EduBook",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "EduBook is your go-to platform for booking classrooms and managing educational resources. Streamline your scheduling with ease.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),

            // Bookings So Far
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bookings So Far",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (bookings.isEmpty)
                    const Text("No bookings yet.")
                  else
                    ...bookings.map((booking) => _buildBookingCard(booking)),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Features",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          "Letter Generation",
                          Icons.description,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildFeatureCard("E-Sign", Icons.edit)),
                    ],
                  ),
                ],
              ),
            ),

            // Departments
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Departments",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...departments.map(
                    (dept) => Column(
                      children: [
                        _buildDepartmentButton(dept.name, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DepartmentView(deptId: dept.id),
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contact Us",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Email: support@edubook.com\nPhone: +1 234 567 890",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    String time =
        "${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}";
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event, color: primaryOrange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Room ${booking.roomId}", // Assuming roomId is the name or fetch room name
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    "$time • ${booking.type}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: primaryOrange),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryOrange,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}
