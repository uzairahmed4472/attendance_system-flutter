import 'dart:io';
import 'package:attendance_system/screens/user/attendance_history_screen.dart';
import 'package:attendance_system/screens/user/edit_profile_screen.dart';
import 'package:attendance_system/screens/user/login_screen.dart';
import 'package:attendance_system/screens/user/request_leave_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDashboardScreen extends StatefulWidget {
  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  User? currentUser;
  String? _profileImageUrl;
  bool _isLoading = true;
  Map<String, dynamic>? userData;

  final String formattedDate =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      fetchUserData(currentUser!.uid);
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      var userDoc = await _firebaseFirestore.collection("users").doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          _profileImageUrl = userData!["profilePictureUrl"] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching user data: $e');
    }
  }

  Future<void> markAttendance(String userId, String status) async {
    CollectionReference usersCollection =
        _firebaseFirestore.collection('users');

    try {
      DocumentReference userDocRef = usersCollection
          .doc(userId)
          .collection('attendanceRecords')
          .doc(formattedDate);
      DocumentSnapshot attendanceDoc = await userDocRef.get();

      if (attendanceDoc.exists) {
        showSnackbar('Attendance already marked for today!', Colors.red);
        return;
      }

      await userDocRef.set({
        'date': formattedDate,
        'status': status,
      });

      showSnackbar('Attendance marked successfully!', Colors.green);
    } catch (error) {
      showSnackbar("Error marking attendance: $error", Colors.red);
    }
  }

  Stream<QuerySnapshot> attendanceStream(String userId) {
    return _firebaseFirestore
        .collection("users")
        .doc(userId)
        .collection("attendanceRecords")
        .orderBy("date", descending: true)
        .snapshots();
  }

  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserLoginScreen()),
              );
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileSection(context),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 35,
              backgroundImage: _profileImageUrl!.isEmpty
                  ? const AssetImage('assets/profile_placeholder.jpeg')
                      as ImageProvider
                  : NetworkImage(_profileImageUrl!),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData != null ? userData!['name'] ?? 'N/A' : 'User Name',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAttendanceStatus(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    return StreamBuilder(
      stream: attendanceStream(currentUser!.uid),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Status: Loading...',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          );
        }
        if (snapshot.hasError) {
          return const Text(
            'Error loading status',
            style: TextStyle(fontSize: 16, color: Colors.red),
          );
        }
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var latestAttendance = snapshot.data!.docs.first;
          String status = latestAttendance['status'];
          String date = latestAttendance['date'];
          return Text(
            'Status: ${date == formattedDate ? status : "Not Marked"}',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          );
        } else {
          return Text(
            'Status: Not Marked',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          );
        }
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.check_circle_outline,
          text: 'Mark Attendance',
          onPressed: () {
            String userId = currentUser!.uid;
            String status = "present";
            markAttendance(userId, status);
          },
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          context,
          icon: Icons.event_note_outlined,
          text: 'Request Leave',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RequestLeaveScreen()),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          context,
          icon: Icons.list_alt_outlined,
          text: 'View Attendance',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AttendanceHistoryScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(text, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 6,
      ),
    );
  }
}
