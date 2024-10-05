import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAttendanceScreen extends StatefulWidget {
  @override
  _ManageAttendanceScreenState createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  String? selectedMonth;
  int selectedYear = DateTime.now().year;
  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  // Fetch users with role 'student' from Firestore
  Future<List<Map<String, dynamic>>> fetchStudentUsers() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'], // Assuming a 'name' field exists
              'profilePictureUrl': doc['profilePictureUrl'] ?? '',
              'attendanceRecords':
                  [], // Attendance records will be fetched separately
            })
        .toList();
  }

  // Fetch attendance records for a specific user filtered by month and year
  Future<List<Map<String, dynamic>>> fetchAttendanceRecords(
      String userId) async {
    if (selectedMonth == null) {
      return []; // Return an empty list if no month is selected
    }

    // Get month index
    int monthIndex = months.indexOf(selectedMonth!) + 1;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('attendanceRecords')
        .where('date',
            isGreaterThanOrEqualTo:
                "$selectedYear-${monthIndex.toString().padLeft(2, '0')}-01")
        .where('date',
            isLessThanOrEqualTo:
                "$selectedYear-${monthIndex.toString().padLeft(2, '0')}-31")
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'date': doc['date'],
              'status': doc['status'],
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month and Year Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  hint: const Text("Select Month"),
                  value: selectedMonth,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedMonth = newValue;
                    });
                  },
                  items: months.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButton<int>(
                  hint: const Text("Select Year"),
                  value: selectedYear,
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedYear = newValue!;
                    });
                  },
                  items:
                      List.generate(10, (index) => DateTime.now().year - index)
                          .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchStudentUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }

                  List<Map<String, dynamic>> students = snapshot.data!;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var student = students[index];

                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundImage: student['profilePictureUrl'] == ""
                                ? const AssetImage(
                                        'assets/profile_placeholder.jpeg')
                                    as ImageProvider
                                : NetworkImage(student['profilePictureUrl']),
                          ),
                          title: Text(student['name']),
                          children: [
                            // Fetch and display attendance records
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: fetchAttendanceRecords(student['id']),
                              builder: (context, attendanceSnapshot) {
                                if (attendanceSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (!attendanceSnapshot.hasData ||
                                    attendanceSnapshot.data!.isEmpty) {
                                  return const Center(
                                      child:
                                          Text('No attendance records found.'));
                                }

                                List<Map<String, dynamic>> attendanceRecords =
                                    attendanceSnapshot.data!;

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: attendanceRecords.length,
                                  itemBuilder: (context, attIndex) {
                                    var attendance =
                                        attendanceRecords[attIndex];

                                    return ListTile(
                                      title:
                                          Text('Date: ${attendance['date']}'),
                                      subtitle: Text(
                                          'Status: ${attendance['status']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              _editAttendanceRecord(
                                                  student['id'],
                                                  attendance['date']);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              _deleteAttendanceRecord(
                                                  student['id'],
                                                  attendance['date']);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Add attendance record
                                _addAttendanceRecord(student['id']);
                              },
                              child: const Text('Add Attendance Record'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to edit an attendance record
  void _editAttendanceRecord(String userId, String date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newStatus = 'present'; // Default selected status
        return AlertDialog(
          title: Text("Edit Attendance for $date"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select new attendance status:"),
              DropdownButton<String>(
                value: newStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    newStatus = newValue!;
                  });
                },
                items: <String>['present', 'absent', 'leave']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without changes
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update attendance record in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('attendanceRecords')
                    .doc(date)
                    .update({
                  'status': newStatus,
                });

                Navigator.of(context).pop(); // Close dialog
                setState(() {}); // Refresh UI
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Function to delete an attendance record
  void _deleteAttendanceRecord(String userId, String date) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('attendanceRecords')
        .doc(date)
        .delete();
    print('Deleted attendance record for $userId on $date');
    setState(() {}); // Refresh UI after deletion
  }

  // Function to add an attendance record
  void _addAttendanceRecord(String userId) {
    DateTime selectedDate = DateTime.now(); // Default to current date
    String attendanceStatus = 'present'; // Default selected status

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Attendance Record"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date Picker
              const Text("Select date:"),
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(
                    "Select Date: ${selectedDate.toLocal()}".split(' ')[0]),
              ),
              const SizedBox(height: 10),
              const Text("Select attendance status:"),
              DropdownButton<String>(
                value: attendanceStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    attendanceStatus = newValue!;
                  });
                },
                items: <String>['present', 'absent', 'leave']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without saving
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save attendance record to Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('attendanceRecords')
                    .doc(selectedDate
                        .toIso8601String()
                        .split('T')[0]) // Store by date
                    .set({
                  'date': selectedDate.toIso8601String().split('T')[0],
                  'status': attendanceStatus,
                });

                Navigator.of(context).pop(); // Close dialog
                setState(() {}); // Refresh UI
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
