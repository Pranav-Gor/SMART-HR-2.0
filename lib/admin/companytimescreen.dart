import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';

class companytimescreen extends StatefulWidget {
  const companytimescreen({super.key});

  @override
  State<companytimescreen> createState() => _companytimescreenState();
}

class _companytimescreenState extends State<companytimescreen> {
  final Color primary = const Color(0xffeef444c);
  late TimeOfDay _checkInTime;
  late TimeOfDay _checkOutTime;
  final TextEditingController QrCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkInTime = TimeOfDay.now();
    _checkOutTime = TimeOfDay.now();
  }

  Future<void> _selectCheckInTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _checkInTime,
    );

    if (pickedTime != null && pickedTime != _checkInTime) {
      setState(() {
        _checkInTime = pickedTime;
      });
    }
  }

  Future<void> _selectCheckOutTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _checkOutTime,
    );

    if (pickedTime != null && pickedTime != _checkOutTime) {
      setState(() {
        _checkOutTime = pickedTime;
      });
    }
  }

  Future<void> _saveTimeToMySQL(BuildContext context) async {
    try {
      DateTime now = DateTime.now();
      DateTime checkInDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );
      DateTime checkOutDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );

      var jsonData = {
        'checkInTime': checkInDateTime.toIso8601String(),
        'checkOutTime': checkOutDateTime.toIso8601String(),
        'date': now.toIso8601String(),
        'qrcode': QrCode.text,
      };

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/companytime.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonData),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Times and QR code saved successfully!')),
          );
          QrCode.clear();
        } else {
          print('Server error: ${jsonResponse['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${jsonResponse['message']}')),
          );
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving data')),
        );
      }
    } catch (error) {
      print('Error saving data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Time Management',
          style: TextStyle(color: Colors.white, fontFamily: 'NexaRegular'),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    onTap: () {},
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
              leading: const Icon(Icons.home),
              title: const Text(
                'Home',
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
                        builder: (context) => const HomeScreen()));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const seminarscreen()));
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
                        builder: (context) => const projectmanagement()));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const showemployee()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee),
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
                  MaterialPageRoute(
                      builder: (context) => const payrollscreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
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
                  MaterialPageRoute(builder: (context) => const showleave()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: primary),
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
                  MaterialPageRoute(
                      builder: (context) => const companytimescreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
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
                      builder: (context) => const departmentmanagement()),
                );
              },
            ),
            const Divider(
              color: Color(0xffeef444c),
              indent: Checkbox.width,
              endIndent: Checkbox.width,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('token');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
            Container(margin: const EdgeInsets.only(top: 35)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Image
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/timem.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Time Selection Card
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      )
                    ]),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTimeTile(
                          context: context,
                          title: 'Check-in Time',
                          time: _checkInTime,
                          onTap: () => _selectCheckInTime(context),
                        ),

                        const Divider(height: 24),

                        _buildTimeTile(
                          context: context,
                          title: 'Check-out Time',
                          time: _checkOutTime,
                          onTap: () => _selectCheckOutTime(context),
                        ),

                        const SizedBox(height: 16),

                        // QR Code Field
                        TextFormField(
                          controller: QrCode,
                          decoration: InputDecoration(
                            labelText: 'QR Code',
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter QR code';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(3, 3),
                        )
                      ]),
                  child: ElevatedButton(
                    onPressed: () {
                      _saveTimeToMySQL(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NexaRegular'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontFamily: 'NexaRegular',
        ),
      ),
      subtitle: Text(
        time.format(context),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'NexaRegular',
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.av_timer_rounded, color: primary, size: 30),
        onPressed: onTap,
      ),
    );
  }
}
