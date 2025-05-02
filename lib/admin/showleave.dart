import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/loginpage.dart';

class showleave extends StatefulWidget {
  const showleave({super.key});

  @override
  State<showleave> createState() => _showleaveState();
}

class _showleaveState extends State<showleave> {
  final Color primary = const Color(0xffeef444c);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchLeaveApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Leave Requests',
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaRegular",
            color: Colors.white,
          ),
        ),
        backgroundColor: primary, // Customizing the app bar color
        iconTheme: const IconThemeData(
          color: Colors.white, // Change this color to your desired color
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xffeef444c),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle gesture
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child: Icon(
                        Icons.person,
                        color: Colors.black26,
                        size: 55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hello, Admin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NexaBold',
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
              ),
              title: Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.redeem),
              title: const Text(
                'Reward Settings',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const adminreward()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text(
                'Registration',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const registrationpage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text(
                'Seminar',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => seminarscreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text(
                'Project Management',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => projectmanagement()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text(
                'View All Employees',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => showemployee()));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.currency_rupee,
              ), // Icon for Payroll
              title: Text(
                'Payroll',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => payrollscreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: primary,
              ), // Icon for Leave Requests
              title: Text(
                'Leave Requests',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                  color: primary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => showleave()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule), // Icon for Leave Requests
              title: const Text(
                'Company Time',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => companytimescreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work), // Icon for Leave Requests
              title: const Text(
                'Department Manage',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => departmentmanagement()),
                );
              },
            ),
            const Divider(
              color: Color(0xffeef444c),
              indent: Checkbox.width,
              endIndent: Checkbox.width,
            ),
            ListTile(
              leading: const Icon(Icons.logout), // Icon for Leave Requests
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () async {
                // Clear token from local storage
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('token');

                // Navigate back to login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 35),
            ),
            const Divider(),
            const ListTile(
              title: Text(
                'Copyright © 2024 TechnoGuide Infosoft',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildLeaveApplications(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLeaveApplications() async {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/leavedetails.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      if (data.isEmpty) {
        print("No leave applications found.");
        return []; // Return an empty list if there are no leave applications
      }

      List<Map<String, dynamic>> pendingApplications = data
          .where((item) => item['status']?.toLowerCase() == 'pending')
          .map((item) => {
                'leaveid': item['leaveID']?.toString() ?? '', // Add this line
                'userid': item['userID']?.toString() ?? '',
                'reason': item['reason'] ?? '',
                'leavetype': item['leaveType'] ?? '',
                'startdate': item['startDate'] != null
                    ? DateTime.tryParse(item['startDate']) ?? DateTime.now()
                    : DateTime.now(),
                'enddate': item['endDate'] != null
                    ? DateTime.tryParse(item['endDate']) ?? DateTime.now()
                    : DateTime.now(),
                'firstname': item['firstName'] ?? '',
                'status': item['status'] ?? '',
              })
          .toList();

      return pendingApplications;
    } else {
      throw Exception(
          'Failed to load leave applications. Status code: ${response.statusCode}, Response: ${response.body}');
    }
  }

  Widget _buildLeaveApplications() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLeaveApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var leaveApplications = snapshot.data ?? [];

        return ListView.builder(
          itemCount: leaveApplications.length,
          itemBuilder: (context, index) {
            var leave = leaveApplications[index];
            var leaveid = leave['leaveid']?.toString() ?? ''; // Add null check
            var reason = leave['reason'] ?? '';
            var startDate = leave['startdate'] ?? DateTime.now();
            var endDate = leave['enddate'] ?? DateTime.now();
            var id = leave['userid'] ?? '';
            var name = leave['firstname'] ?? '';
            var leavetype = leave['leavetype'] ?? '';
            var status = leave['status'] ?? '';
            var dateFormatter = DateFormat('yyyy-MM-dd');
            var formattedStartDate = dateFormatter.format(startDate);
            var formattedEndDate = dateFormatter.format(endDate);

            // Calculate the number of days between start date and end date
            var duration = endDate.difference(startDate);
            var leaveTimeInDays = duration.inDays;

            // Adjust leave duration display if start date and end date are the same
            if (startDate == endDate) {
              leaveTimeInDays = 1;
            }

            return Container(
              width: 330,
              height: 300,
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  'Reason: $reason',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "NexaBold",
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.contact_mail_outlined,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 40, width: 8),
                            Text(
                              'Employee ID: $id',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "NexaBold",
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 40, width: 8),
                            Text(
                              'Leave Type: $leavetype',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "NexaBold",
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 40, width: 8),
                            Text(
                              'Start Date: $formattedStartDate',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "NexaBold",
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 40, width: 8),
                            Text(
                              'End Date: $formattedEndDate',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "NexaBold",
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Leave Duration: $leaveTimeInDays days',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "NexaBold",
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(
                                    0.3), // Shadow color with opacity
                                blurRadius: 10, // Softness of the shadow
                                spreadRadius: 1, // How much the shadow spreads
                                offset: Offset(
                                    3, 4), // Position of the shadow (X, Y)
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final currentStatus = "Approved";
                              if (leaveid?.isNotEmpty ?? false) {
                                _updateLeaveStatus(
                                    context, leaveid, currentStatus);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Background color
                              foregroundColor: Colors.white,
                              elevation: 5, // Text color// Elevation
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14), // BorderRadius
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 15), // Padding
                            ),
                            icon: Icon(
                              Icons.thumb_up,
                              color: Colors.white,
                            ),
                            label: Text('Approve'),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 110,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(
                                    0.3), // Shadow color with opacity
                                blurRadius: 10, // Softness of the shadow
                                spreadRadius: 1, // How much the shadow spreads
                                offset: Offset(
                                    3, 4), // Position of the shadow (X, Y)
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final currentStatus = "Rejected";
                              if (leaveid?.isNotEmpty ?? false) {
                                _updateLeaveStatus(
                                    context, leaveid, currentStatus);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Background color
                              foregroundColor: Colors.white,
                              elevation: 5, // Text color// Elevation
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14), // BorderRadius
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 15), // Padding
                            ),
                            icon: Icon(
                              Icons.thumb_down,
                              color: Colors.white,
                            ),
                            label: Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateLeaveStatus(
      BuildContext context, String leaveid, String status) async {
    try {
      if (leaveid == null ||
          leaveid.isEmpty ||
          status == null ||
          status.isEmpty) {
        throw Exception('Leave ID and status cannot be empty');
      }

      print('Original leaveid: $leaveid'); // Debug print

      // First, validate inputs
      if (leaveid.isEmpty || status.isEmpty) {
        throw Exception('Leave ID and status cannot be empty');
      }

      // Print the leave ID before processing
      print('Processing leave ID: $leaveid');

      // Create the request body
      final body = jsonEncode({
        'userid': leaveid,
        'status': status,
      });

      print('Request body: $body'); // Debug print

      // Send the request
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/updateleavestatus.php'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse the response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the leave applications list
        setState(() {
          _fetchLeaveApplications();
        });
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to update leave status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
