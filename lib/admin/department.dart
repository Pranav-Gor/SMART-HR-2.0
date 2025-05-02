import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/adddepartment.dart';
import 'package:smart_hr/admin/addjobtitle.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';

class departmentmanagement extends StatefulWidget {
  const departmentmanagement({super.key});

  @override
  State<departmentmanagement> createState() => _departmentmanagementState();
}

class _departmentmanagementState extends State<departmentmanagement> {
  Color primary = const Color(0xffeef444c);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Management',
          style: TextStyle(color: Colors.white, fontFamily: 'NexaRegular'),
        ),
        backgroundColor: Colors.redAccent,
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
              leading: Icon(
                Icons.schedule,
                color: primary,
              ), // Icon for Leave Requests
              title: Text(
                'Company Time',
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              buildInteractiveCard(
                context,
                'Department Details',
                Icons.home_work,
                Color.fromARGB(255, 99, 97, 97),
                () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddDepartmentScreen()));
                },
              ),
              SizedBox(height: 16),
              buildInteractiveCard(
                context,
                'Jobtitle Details',
                Icons.format_list_bulleted_add,
                const Color.fromARGB(255, 125, 143, 104),
                () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => JobTitleManagement()));
                },
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInteractiveCard(
    BuildContext context,
    String cardTitle,
    IconData icon,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        color: backgroundColor,
        child: Container(
          width: 300,
          height: 150,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                cardTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppBarTitle() {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: 'Department',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: ' Management',
            style: TextStyle(
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
