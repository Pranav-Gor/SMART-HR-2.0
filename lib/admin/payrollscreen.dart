import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/salaryscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';
import 'package:external_path/external_path.dart';

class payrollscreen extends StatefulWidget {
  const payrollscreen({Key? key}) : super(key: key);

  @override
  _payrollscreenState createState() => _payrollscreenState();
}

class _payrollscreenState extends State<payrollscreen> {
  final Color primary = const Color(0xffeef444c);
  List _users = []; // Assuming this is your list of users
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response =
    await http.get(Uri.parse('http://192.168.29.211/hr_api/Payroll_Emp.php'));
    if (response.statusCode == 200) {
      setState(() {
        _users = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> _downloadExcel() async {
    if (_users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No employee data available')));
      return;
    }

    try {
      final xls = excel.Excel.createExcel();
      final sheet = xls['Sheet1'];

      // Add headers
      final headers = [
        'User ID', 'Name', 'Email', 'Department', 'Net Salary', 'Total Salary' , 'Salary Date'
      ];
      sheet.appendRow(headers);

      // Add data rows
      for (var user in _users) {
        sheet.appendRow([
          user['userID']?.toString() ?? '',
          '${user['firstName']} ${user['lastName']}',
          user['email']?.toString() ?? '',
          user['deptName']?.toString() ?? '',
          user['netSalary']?.toString() ?? '',
          user['total_salary']?.toString() ?? 'N/A',
          user['salary_dates']?.toString() ?? 'N/A',
        ]);
      }

      // Get app directory
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'PayrollReport_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${dir.path}/$fileName';

      // Save file
      final fileBytes = xls.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Show success and open file
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved as $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      print('Excel error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  Future<void> _selectDateAndDownload() async {
    // Show date picker for start date
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow 1 year ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );

    if (startDate != null) {
      // Show date picker for end date
      final DateTime? endDate = await showDatePicker(
        context: context,
        initialDate: startDate.add(const Duration(days: 1)),
        firstDate: startDate,
        lastDate: DateTime.now().add(const Duration(days: 365)), // Allow 1 year ahead
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primary),
            ),
            child: child!,
          );
        },
      );

      if (endDate != null) {
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
        });
        _generateFilteredExcel();
      }
    }
  }

  Future<void> _generateFilteredExcel() async {
    // Filter users based on salary_dates
    final filteredUsers = _users.where((user) {
      if (user['salary_dates'] == null) return false;

      DateTime? salaryDate;
      try {
        salaryDate = DateTime.parse(user['salary_dates'].toString().split(',')[0]);
      } catch (e) {
        return false;
      }

      return salaryDate.isAfter(_startDate!) &&
          salaryDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();

    if (filteredUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available for selected date range')));
      return;
    }

    try {
      final xls = excel.Excel.createExcel();
      final sheet = xls['Sheet1'];

      // Add date range info
      sheet.appendRow([
        'Payroll Report',
        'From: ${_startDate!.toString().split(' ')[0]}',
        'To: ${_endDate!.toString().split(' ')[0]}'
      ]);
      sheet.appendRow([]); // Empty row for spacing

      // Add headers
      final headers = [
        'User ID', 'Name', 'Email', 'Department', 'Net Salary',
        'Total Salary', 'Salary Date'
      ];
      sheet.appendRow(headers);

      // Add filtered data rows
      for (var user in filteredUsers) {
        sheet.appendRow([
          user['userID']?.toString() ?? '',
          '${user['firstName']} ${user['lastName']}',
          user['email']?.toString() ?? '',
          user['deptName']?.toString() ?? '',
          user['netSalary']?.toString() ?? '',
          user['total_salary']?.toString() ?? 'N/A',
          user['salary_dates']?.toString() ?? 'N/A',
        ]);
      }

      // Get root storage path
      String? downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD // Fixed: removed 'S' from DOWNLOADS
      );

      if (downloadPath == null) {
        throw Exception('Could not access download directory');
      }

      final fileName = 'PayrollReport_${_startDate!.toString().split(' ')[0]}_to${_endDate!.toString().split(' ')[0]}.xlsx';
      final filePath = '$downloadPath/$fileName';

      final fileBytes = xls.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to Downloads: $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      print('Excel error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Employees Salary',
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
                color: primary,
              ), // Icon for Payroll
              title: Text(
                'Payroll',
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
          SizedBox(
            height: 10,
          ),
          Center(
            child: Container(
              width: 340,
              height: 240,
              margin: EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.asset(
                'assets/images/esal.jpg',
              ),
            ),
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

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: primary,
                      child: Text(
                        fullName.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
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
                      String userid = user['userID'];
                      // Navigate to employee details screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalaryPage(employeeId: userid),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: _selectDateAndDownload,
        tooltip: 'Download Excel Report',
        child: const Icon(Icons.download_rounded, color: Colors.white),
      ),
    );
  }
}