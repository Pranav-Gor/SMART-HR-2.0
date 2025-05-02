import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';
import 'package:confetti/confetti.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color(0xffeef444c);
  String qrData = '';
  String statusMessage = '';
  bool isOfficeHours = false;
  bool _isOfficeClosed = false;
  bool _hasShownWaitingMessage = false;
  late Timer _qrUpdateTimer;
  late ConfettiController _confettiController;
  int _qrCounter = 0;
  String _baseQRCode = '';
  static const String QR_KEY = 'current_qr';
  static const String QR_HISTORY_KEY = 'qr_history';
  List<Map<String, dynamic>> qrHistory = [];
  late SharedPreferences prefs;
  String _previousQRCode = '';
  DateTime _lastQRUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    await _loadQRHistory();
    _startQRUpdates();
  }

  Future<void> _loadQRHistory() async {
    final historyJson = prefs.getString(QR_HISTORY_KEY);
    if (historyJson != null) {
      setState(() {
        qrHistory = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      });
    }
  }

  void _startQRUpdates() {
    _fetchQRCode(); // Initial fetch
    _qrUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _fetchQRCode());
  }

  Future<void> _fetchQRCode() async {
    if (_isOfficeClosed) return;

    try {
      final response = await http.get(
          Uri.parse('http://192.168.29.211/hr_api/fetchqrcode_admin.php'));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        print('\n----------------------------------------');
        print('Time: ${DateTime.now().toString()}');
        print('Response Data: ${json.encode(data)}');
        setState(() {
          switch (data['status']) {
            case 'active':
              _hasShownWaitingMessage = false;

              // Reset counter if QR base changed or time gap > 10 seconds
              final currentTime = DateTime.now();
              if (_baseQRCode != data['qrcode'] ||
                  currentTime.difference(_lastQRUpdate).inSeconds > 10) {
                _baseQRCode = data['qrcode'];
                _qrCounter = 0;
                _previousQRCode = '';
              }

              // Generate new QR only if different from previous
              String newQR = _baseQRCode + _qrCounter.toString();
              if (newQR != _previousQRCode) {
                print('New QR Generated:');
                print('Base QR: $_baseQRCode');
                print('Counter: $_qrCounter');
                print('Full QR: $newQR');

                qrData = newQR;
                _previousQRCode = qrData;
                _lastQRUpdate = currentTime;
                _qrCounter++;
              }

              statusMessage =
                  'Office Hours: ${data['checkIn']} - ${data['checkOut']}';
              isOfficeHours = true;
              _sendQRDataToBackend(qrData, 0, 'waiting');
              break;
            case 'waiting':
              if (!_hasShownWaitingMessage) {
                print('Time Status: waiting');
                print('QR Code: ');
                print('Counter: 0');
                print('Message: Office starts at ${data['checkIn']}');
                _hasShownWaitingMessage = true;
              }
              qrData = '';
              _qrCounter = 0;
              statusMessage = 'Office starts at ${data['checkIn']}';
              isOfficeHours = false;
              _sendQRDataToBackend('', 0, 'waiting');
              break;

            case 'closed':
              if (!_isOfficeClosed) {
                _isOfficeClosed = true;
                _clearAllData(); // Clear all stored data
                statusMessage = 'Office hours ended';
                isOfficeHours = false;
                print('Time Status: closed');
                print('Memory cleared');
                _qrUpdateTimer.cancel();
              }
              break;
            default:
              qrData = '';
              _qrCounter = 0;
              statusMessage = data['message'] ?? 'Unable to get office status';
              isOfficeHours = false;
          }
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _clearAllData() async {
    await prefs.clear(); // Clear all SharedPreferences
    setState(() {
      qrData = '';
      _qrCounter = 0;
      _baseQRCode = '';
      _previousQRCode = '';
      qrHistory.clear();
    });
  }

  Future<void> _sendQRDataToBackend(
      String qrData, int counter, String status) async {
    try {
      final response = await http.post(
          Uri.parse('http://192.168.29.211/hr_api/save_qr_history.php'),
          body: {
            'qr_code': qrData,
            'counter': counter.toString(),
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
          });

      if (response.statusCode == 200) {
        print('QR Data saved to backend: $qrData');
      } else {
        print('Failed to save QR data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending QR data: $e');
    }
  }

  @override
  void dispose() {
    _qrUpdateTimer.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          'Smart HR',
          style: TextStyle(
            fontFamily: 'NexaBold',
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            focusColor: primary,
            onPressed: () async {
              // Clear token from local storage
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.remove('token');

              // Navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
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
                color: primary,
              ),
              title: Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                  color: primary,
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
                  MaterialPageRoute(
                      builder: (context) => const payrollscreen()),
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
                  MaterialPageRoute(builder: (context) => const showleave()),
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
                  MaterialPageRoute(
                      builder: (context) => const companytimescreen()),
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
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Welcome,",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Admin",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 25, bottom: 5),
              child: Text(
                "Generate QR Code",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: DateTime.now().day.toString(),
                  style: TextStyle(
                    color: primary,
                    fontSize: screenWidth / 18,
                    fontFamily: "NexaBold",
                  ),
                  children: [
                    TextSpan(
                        text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth / 20,
                        )),
                  ],
                ),
              ),
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }),
            const SizedBox(height: 15),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary, // Background color
                  foregroundColor: Colors.white, // Text color
                  elevation: 5, // Elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // BorderRadius
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 20), // Padding
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Scan the QR Code!',
                      style: TextStyle(fontSize: 18, fontFamily: 'NexaRegular'),
                    ),
                  ],
                ),
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ],
        ),
      ),
    );
  }
}
