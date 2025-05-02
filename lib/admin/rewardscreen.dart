import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/adminpointaccumulation.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';

class adminreward extends StatefulWidget {
  const adminreward({super.key});

  @override
  State<adminreward> createState() => _adminrewardState();
}

class _adminrewardState extends State<adminreward> {
  Color primary = const Color(0xffeef444c);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reward Settings',
          style: TextStyle(
            fontFamily: 'NexaRegular',
            color: Colors.white,
          ),
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
              leading: Icon(
                Icons.redeem,
                color: primary,
              ),
              title: Text(
                'Reward Settings',
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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/myrwd.jpg',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 70),
            Expanded(
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle the button press for Container 1
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminPointAccumulation(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary, // Background color
                          foregroundColor: Colors.white, // Text color
                          elevation: 5, // Elevation
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // BorderRadius
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20), // Padding
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.yellow), // Icon
                            SizedBox(width: 8),
                            Text(
                              'Point Accumulation Settings',
                              style: TextStyle(
                                  fontSize: 16, fontFamily: 'NexaRegular'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
