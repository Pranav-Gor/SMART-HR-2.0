import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/salaryscreen.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/employee/leavescreen.dart';
import 'package:smart_hr/employee/myrewards.dart';
import 'package:smart_hr/employee/mytask.dart';
import 'package:smart_hr/employee/salarydatascreen.dart';
import 'package:smart_hr/employee/traindevscreen.dart';
import 'package:smart_hr/loginpage.dart';

class MyDrawer extends StatefulWidget {
  final String employeeId;
  final Uint8List? profilePicBytes;

  const MyDrawer({required this.employeeId, this.profilePicBytes});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  int _selectedIndex = 0; // State variable to keep track of the selected index
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  String firstName = ""; // Variable to store the user's first name
  final Color primary = const Color(0xffeef444c);

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);

        final employeeData = employeeList.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeeData == null) {
          throw Exception(
              'Employee data not found for user ID: ${widget.employeeId}');
        }

        final profilePic = employeeData['photo'];
        final String? userFirstName =
            employeeData['firstName']; // Fetch first name from API

        if (profilePic != null && profilePic.isNotEmpty) {
          profilePicBytes = base64Decode(profilePic);
        }

        setState(() {
          profilePicLink =
              profilePicBytes != null ? base64Encode(profilePicBytes!) : "";
          firstName = userFirstName ?? ""; // Update first name
        });
      } else {
        throw Exception(
            'Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employee data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Handle the tap event
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: profilePicBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              profilePicBytes!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.black26,
                            size: 55,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hello, $firstName', // Display first name instead of user ID
                  style: const TextStyle(
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
            ), // Icon for Home
            title: Text(
              'Home',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => emphomescreen(widget.employeeId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.redeem), // Icon for Rewards
            title: const Text(
              'Rewards',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyReward(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.school), // Icon for Training & Development
            title: const Text(
              'Training & Development',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      traindevscreen(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment), // Icon for My Tasks
            title: const Text(
              'My Tasks',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => mytask(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.calendar_today_outlined), // Icon for Leave
            title: const Text(
              'Leave',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      leavescreen(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee), // Icon for Salary
            title: const Text(
              'Salary',
              style: TextStyle(
                fontFamily: 'NexaRegular',
                fontSize: 17,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SalaryScreen(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          const Divider(
            color: Color(0xffeef444c),
            indent: Checkbox.width,
            endIndent: Checkbox.width,
          ),
          ListTile(
            leading: const Icon(Icons.logout), // Icon for Logout
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
            margin: const EdgeInsets.only(top: 150),
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
    );
  }
}
