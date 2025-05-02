import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/employeedetailscreen.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';

class showemployee extends StatefulWidget {
  const showemployee({Key? key}) : super(key: key);

  @override
  _showemployeeState createState() => _showemployeeState();
}

class _showemployeeState extends State<showemployee> {
  List _users = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response =
        await http.get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _users = data.map((user) {
          // Check if the photo field is a valid base64 string
          if (user['photo'] != null && user['photo'].isNotEmpty) {
            try {
              // Attempt to decode the base64 string
              user['profilePic'] = base64Decode(user['photo']);
            } catch (e) {
              // If decoding fails, log the error and set profilePic to null
              print('Error decoding base64 image: $e');
              user['profilePic'] = null;
            }
          } else {
            // If photo is null or empty, set profilePic to null
            user['profilePic'] = null;
          }
          return user;
        }).toList();
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xffeef444c);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Employees List',
          style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
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
              leading: Icon(
                Icons.people,
                color: primary,
              ),
              title: Text(
                'View All Employees',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                  color: primary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => showemployee()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee), // Icon for Payroll
              title: const Text(
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
              leading:
                  const Icon(Icons.calendar_today), // Icon for Leave Requests
              title: const Text(
                'Leave Requests',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
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
      body: Column(
        children: [
          Container(
            width: 411,
            height: 240,
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Lottie.asset("assets/lemp.json"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length, // Use the length of the users list
              itemBuilder: (context, index) {
                final user = _users[index];
                print("user:$user");
                final String fullName =
                    '${user['firstName']} ${user['lastName']}';
                final String email = user['email'];
                final String employeeId = user['userID'];
                return Card(
                  elevation: 7,
                  shadowColor: Colors.black,
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      radius: 30, // Adjust size
                      backgroundColor:
                          Colors.grey[300], // Placeholder background
                      backgroundImage: user['profilePic'] != null
                          ? MemoryImage(user['profilePic']) // Load from memory
                          : null,
                      child: (user['profilePic'] == null)
                          ? Text(
                              fullName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 35, color: Colors.red),
                            )
                          : null, // No text if image exists
                    ),
                    title: Text(
                      fullName.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      // Navigate to employee details screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              employeedetails(employeeId: employeeId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
