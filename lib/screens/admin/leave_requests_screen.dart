import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveRequestsScreen extends StatefulWidget {
  @override
  _LeaveRequestsScreenState createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  List<Map<String, dynamic>> _pendingLeaveRequests = [];

  @override
  void initState() {
    super.initState();
    _loadPendingLeaveRequests();
  }

  Future<void> _loadPendingLeaveRequests() async {
    List<Map<String, dynamic>> requests = await _fetchPendingLeaveRequests();
    setState(() {
      _pendingLeaveRequests = requests;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPendingLeaveRequests() async {
    List<Map<String, dynamic>> pendingRequests = [];

    // Fetch users who have leave requests
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    // Loop through each user to get pending leave requests
    for (var userDoc in usersSnapshot.docs) {
      QuerySnapshot leaveRequestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('leaveRequests')
          .where('status', isEqualTo: 'pending')
          .get();

      for (var leaveRequestDoc in leaveRequestsSnapshot.docs) {
        pendingRequests.add({
          'userId': userDoc.id,
          'userName': userDoc['name'],
          'leaveRequestId': leaveRequestDoc.id,
          'leaveRequestData': leaveRequestDoc.data(),
        });
      }
    }

    return pendingRequests;
  }

  void _approveLeaveRequest(
      String userId, String leaveRequestId, String leaveDate) async {
    // Update the leave request status to "approved"
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('leaveRequests')
        .doc(leaveRequestId)
        .update({
      'status': 'approved',
      'adminComment': 'Approved due to valid reason',
    });

    // Update the attendance record for the same date to "leave"
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('attendanceRecords')
        .doc(leaveDate) // leaveDate should be the date in yyyy-MM-dd format
        .set(
            {
          'date': leaveDate,
          
          'status': 'leave',
        },
            SetOptions(
                merge:
                    true)); // SetOptions(merge: true) ensures that only 'status' field is updated
  }

  void _rejectLeaveRequest(
      String userId, String leaveRequestId, String leaveDate) async {
    // Update the leave request status to "rejected"
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('leaveRequests')
        .doc(leaveRequestId)
        .update({
      'status': 'rejected',
      'adminComment': 'Reason not valid',
    });

    // Update the attendance record for the same date to "absent"
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('attendanceRecords')
        .doc(leaveDate)
        .set({
      'date': leaveDate,
     
      'status': 'absent',
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Leave Requests'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _pendingLeaveRequests.length,
          itemBuilder: (context, index) {
            var request = _pendingLeaveRequests[index];
            var leaveRequest = request['leaveRequestData'];

            return Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text(request['userName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leave Date: ${leaveRequest['date']}'),
                    Text('Reason: ${leaveRequest['reason']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        // Approve leave request and mark attendance as "leave"
                        _approveLeaveRequest(
                            request['userId'],
                            request['leaveRequestId'],
                            leaveRequest['date'] // Pass the leave date
                            );
                        setState(() {
                          _pendingLeaveRequests
                              .removeAt(index); // Remove from UI after approval
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        // Reject leave request and mark attendance as "absent"
                        _rejectLeaveRequest(
                            request['userId'],
                            request['leaveRequestId'],
                            leaveRequest['date'] // Pass the leave date
                            );
                        setState(() {
                          _pendingLeaveRequests.removeAt(
                              index); // Remove from UI after rejection
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
