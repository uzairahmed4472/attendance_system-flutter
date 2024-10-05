import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> attendanceList = [];
  Map<String, int> attendanceStats = {
    'present': 0,
    'absent': 0,
    'leave': 0,
  };
  User? currentUser;
  bool _isLoading = false;
  String _errorMessage = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 2, vsync: this);
    if (currentUser != null) {
      fetchAttendanceDataForMonth(currentUser!.uid);
    } else {
      print("No user logged in");
    }
  }

  Future<void> fetchAttendanceDataForMonth(String userId) async {
    _isLoading = true;
    try {
      CollectionReference attendanceCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('attendanceRecords');

      DateTime now = DateTime.now();
      String currentMonth = DateFormat('yyyy-MM').format(now);

      QuerySnapshot querySnapshot = await attendanceCollection
          .where('date', isGreaterThanOrEqualTo: "$currentMonth-01")
          .where('date', isLessThanOrEqualTo: "$currentMonth-31")
          .orderBy('date', descending: true)
          .get();

      attendanceList.clear();
      attendanceStats = {'present': 0, 'absent': 0, 'leave': 0};

      if (querySnapshot.docs.isEmpty) {
        _errorMessage = "No attendance records for this month.";
        setState(() {
          _isLoading = false;
        });
        return;
      }

      for (var doc in querySnapshot.docs) {
        String status = doc['status'];
        attendanceList.add({
          'date': doc['date'],
          'status': status,
        });
        attendanceStats[status] = attendanceStats[status]! + 1;
      }

      setState(() {
        _isLoading = false;
      });
    } on SocketException {
      _errorMessage = "Internet not connected";
    } catch (error) {
      _errorMessage = "Error fetching attendance data: $error";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Daily Attendance"),
            Tab(text: "Monthly Stats"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyAttendanceTab(),
                _buildMonthlyStatsTab(),
              ],
            ),
    );
  }

  Widget _buildDailyAttendanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: attendanceList.isEmpty
          ? Center(
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final record = attendanceList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      _getStatusIcon(record['status']!),
                      color: _getStatusColor(record['status']!),
                    ),
                    title: Text(
                      record['date']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Status: ${record['status']}'),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMonthlyStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Stats for ${DateFormat('MMMM yyyy').format(DateTime.now())}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatCard("Present", attendanceStats['present']!, Colors.green),
          const SizedBox(height: 10),
          _buildStatCard("Absent", attendanceStats['absent']!, Colors.red),
          const SizedBox(height: 10),
          _buildStatCard("Leave", attendanceStats['leave']!, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.7),
          child: Text(
            "$count",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Helper function to get icon based on attendance status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_outline;
      case 'absent':
        return Icons.cancel_outlined;
      case 'leave':
        return Icons.event_busy_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Helper function to get color based on attendance status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
