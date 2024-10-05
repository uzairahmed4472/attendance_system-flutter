import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For loading indicator

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;
  String selectedReportType = 'User Specific';
  String? selectedUserId;
  bool isLoading = false;

  List<Map<String, dynamic>> reportData = [];
  Map<String, int> summary = {'present': 0, 'leave': 0, 'absent': 0};

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  // Method to select a date
  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, bool isFromDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        if (isFromDate) {
          fromDate = pickedDate;
        } else {
          toDate = pickedDate;
        }
      });
    }
  }

  // Generate User-specific Attendance Report
  Future<void> _generateUserReport(String userId) async {
    if (fromDate == null || toDate == null) {
      _showErrorSnackbar('Please select both from and to dates.');
      return;
    }
    setState(() {
      isLoading = true;
      reportData.clear();
    });

    QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('attendanceRecords')
        .where('date', isGreaterThanOrEqualTo: fromDateController.text)
        .where('date', isLessThanOrEqualTo: toDateController.text)
        .get();

    int presentCount = 0;
    int leaveCount = 0;
    int absentCount = 0;

    for (var attendanceDoc in attendanceSnapshot.docs) {
      String status = attendanceDoc['status'];
      if (status == 'present') presentCount++;
      if (status == 'leave') leaveCount++;
      if (status == 'absent') absentCount++;
    }

    String grade = _calculateGrade(presentCount);

    reportData.add({
      'name': 'User Name', // Replace with actual user name if available
      'present': presentCount,
      'leave': leaveCount,
      'absent': absentCount,
      'grade': grade,
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _generateSystemReport() async {
    if (fromDate == null || toDate == null) {
      _showErrorSnackbar('Please select both from and to dates.');
      return;
    }
    setState(() {
      isLoading = true;
      reportData.clear();
      summary = {'present': 0, 'leave': 0, 'absent': 0};
    });

    try {
      QuerySnapshot systemAttendanceSnapshot = await FirebaseFirestore.instance
          .collectionGroup('attendanceRecords')
          .where('date', isGreaterThanOrEqualTo: fromDateController.text)
          .where('date', isLessThanOrEqualTo: toDateController.text)
          .get();

      for (var attendanceDoc in systemAttendanceSnapshot.docs) {
        String status = attendanceDoc['status'];
        if (status == 'present') summary['present'] = summary['present']! + 1;
        if (status == 'leave') summary['leave'] = summary['leave']! + 1;
        if (status == 'absent') summary['absent'] = summary['absent']! + 1;
      }

      reportData.add({
        'name': 'System-Wide Report',
        'present': summary['present'],
        'leave': summary['leave'],
        'absent': summary['absent'],
        'grade': 'N/A',
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        _showErrorSnackbar(
            'The required index is still being created. Please try again later.');
      } else {
        _showErrorSnackbar('An error occurred: ${e.toString()}');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to calculate grade
  String _calculateGrade(int presentCount) {
    if (presentCount >= 26) {
      return 'A';
    } else if (presentCount >= 20) {
      return 'B';
    } else if (presentCount >= 15) {
      return 'C';
    } else {
      return 'D';
    }
  }

  // Show error snack bar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  // Switch between User-specific and System-wide reports
  void _toggleReportType(String? type) {
    setState(() {
      selectedReportType = type!;
      reportData.clear(); // Reset data on type change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Reports'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Switch between User-specific and System-wide reports
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('User Specific'),
                    value: 'User Specific',
                    groupValue: selectedReportType,
                    onChanged: _toggleReportType,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('System-Wide'),
                    value: 'System-Wide',
                    groupValue: selectedReportType,
                    onChanged: _toggleReportType,
                  ),
                ),
              ],
            ),

            // Fetch users dynamically from Firestore and display in the dropdown
            if (selectedReportType == 'User Specific')
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where("role", isEqualTo: "student")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  List<DropdownMenuItem<String>> userItems = [];
                  for (var user in snapshot.data!.docs) {
                    var userId = user.id;
                    var userName = user[
                        'name']; // Assumes 'name' is a field in 'users' collection
                    userItems.add(
                      DropdownMenuItem(
                        value: userId,
                        child: Text(userName),
                      ),
                    );
                  }
                  return DropdownButton<String>(
                    value: selectedUserId,
                    hint: Text('Select User'),
                    isExpanded: true,
                    items: userItems,
                    onChanged: (value) {
                      setState(() {
                        selectedUserId = value;
                      });
                    },
                  );
                },
              ),

            SizedBox(height: 16),

            // Date pickers
            TextField(
              controller: fromDateController,
              decoration: InputDecoration(
                labelText: 'From Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectDate(context, fromDateController, true),
              readOnly: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: toDateController,
              decoration: InputDecoration(
                labelText: 'To Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectDate(context, toDateController, false),
              readOnly: true,
            ),
            SizedBox(height: 32),

            // Generate Report button
            ElevatedButton(
              onPressed: selectedReportType == 'User Specific'
                  ? selectedUserId == null
                      ? null
                      : () => _generateUserReport(selectedUserId!)
                  : _generateSystemReport,
              child: Text('Generate Report'),
            ),
            SizedBox(height: 16),

            // Loading indicator
            if (isLoading)
              SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),

            // Display report data in a table
            if (reportData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: reportData.length,
                  itemBuilder: (context, index) {
                    final data = reportData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        child: ListTile(
                          title: Text('${data['name']}'),
                          subtitle: Text(
                              'Present: ${data['present']}, Leave: ${data['leave']}, Absent: ${data['absent']}'),
                          trailing: Text('Grade: ${data['grade']}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
