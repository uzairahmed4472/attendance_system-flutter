import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestLeaveScreen extends StatefulWidget {
  @override
  _RequestLeaveScreenState createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final TextEditingController leaveReasonController = TextEditingController();
  DateTime? selectedDate;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDate == null
                    ? 'Select Date for Leave Request'
                    : 'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // DatePicker to select leave date
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : 'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: leaveReasonController,
                autocorrect: true,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Leave Reason'),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitLeaveRequest,
                  child: const Text('Submit Leave'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Default to current date
      firstDate: DateTime(2000), // Minimum date
      lastDate: DateTime(2101), // Maximum date
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    // Check if a date has been selected and the reason is provided
    if (selectedDate == null || leaveReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    // Format the selected date to a string (e.g., '2024-10-01')
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

    try {
      // Reference to the user's 'leaveRequests' subcollection
      DocumentReference userLeaveRequestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid) // Document ID is the user's uid
          .collection('leaveRequests') // Subcollection for leave requests
          .doc(formattedDate); // Document ID is the selected date

      // Check if the leave request already exists for the selected date
      DocumentSnapshot leaveRequestDoc = await userLeaveRequestRef.get();
      if (leaveRequestDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Leave request already submitted for this date.')),
        );
        return;
      }

      // Data for the new leave request
      Map<String, dynamic> leaveRequestData = {
        'date': formattedDate, // Store the leave request date
        'reason': leaveReasonController.text, // User's leave reason
        'status': 'pending', // Initial status is 'pending'
        'adminComment': '', // Admin comment, initially empty
        'submittedAt': FieldValue.serverTimestamp(), // Timestamp of submission
      };

      // Submit the leave request to Firestore
      await userLeaveRequestRef.set(leaveRequestData);

      // Notify the user of successful submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully')),
      );

      // Clear the form after submission
      setState(() {
        leaveReasonController.clear();
        selectedDate = null;
      });
    } catch (error) {
      // Handle submission failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit leave request: $error')),
      );
    }
  }
}
