import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/employee/leavescreen.dart';
import 'package:smart_hr/employee/myrewards.dart';
import 'package:smart_hr/employee/mytask.dart';
import 'package:smart_hr/employee/salarydatascreen.dart';
import 'package:smart_hr/employee/traindevscreen.dart';
import 'package:smart_hr/loginpage.dart';

import 'employeedrawer.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key, required this.employeeId}) : super(key: key);
  final String employeeId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late double screenHeight;
  late double screenWidth;
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  Color primary = const Color(0xffeef444c);

  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));

      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);

        // Find the employee with the matching user ID
        final employeeData = employeeList.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null, // Use null if no matching data is found
        );

        if (employeeData == null) {
          throw Exception(
              'Employee data not found for user ID: ${widget.employeeId}');
        }

        // Extract employee details (you can include other details here)
        // Removed profile picture-related code

        setState(() {
          // Set other details as needed
          print(
              "Employee Name: ${employeeData['name']}"); // Correctly extract the name
        });
      } else {
        setState(() {
          // Handle API failure scenario
        });
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employee data: $e')),
      );
    }
  }

  // Future<List<Map<String, dynamic>>> fetchEmployeeRecordsFromAPI(
  //     String employeeId) async {
  //   // Define your API endpoint URL
  //   final apiUrl = 'http://192.168.29.97:8080/hr_api/showattendance.php';

  //   try {
  //     final response = await http.get(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);

  //       List<Map<String, dynamic>> records = [];
  //       for (var record in jsonData) {
  //         records.add(Map<String, dynamic>.from(record));
  //       }
  //       return records;
  //     } else {
  //       // If the request was not successful, throw an exception or handle the error
  //       throw Exception(
  //           'Failed to fetch employee records: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     // Handle any errors that occur during the HTTP request
  //     print('Error fetching employee records: $e');
  //     throw e; // Optionally rethrow the exception for upper layers to handle
  //   }
  // }

  Future<List<Map<String, dynamic>>> fetchEmployeeRecordsFromAPI(
      String employeeId, DateTime selectedMonth) async {
    // Define your API endpoint URL
    final apiUrl = 'http://192.168.29.211/hr_api/showattendance.php';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("jsonData: $jsonData");

        // Extract the list of records from jsonData['data']
        List<Map<String, dynamic>> records = [];
        var data = jsonData['data']; // Access the 'data' field

        // Filter records based on employee_id and month
        for (var record in data) {
          // Check if employee_id exists and is not null
          if (record['userID'] != null &&
              record['userID'].toString() == employeeId) {
            print("Record: $record");

            // Ensure check_in exists and is not null before parsing the date
            if (record['checkIn'] != null) {
              DateTime attendanceDate = DateTime.parse(
                  record['checkIn']); // Assuming check_in represents the date
              print("AttendanceDate: $attendanceDate");

              var verdate = attendanceDate.month.toString().padLeft(2, '0');
              print("Verified month: $verdate");

              var month = selectedMonth.month.toString().padLeft(2, '0');
              print("Selected month: $month");

              if (verdate == month) {
                records.add(Map<String, dynamic>.from(record));
              }
            } else {
              print("check_in is null for this record");
            }
          } else {
            print("Employee ID is null or does not match: ${record['userID']}");
          }
        }

        print("Filtered Records: $records");
        return records;
      } else {
        // If the request was not successful, throw an exception or handle the error
        throw Exception(
            'Failed to fetch employee records: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
      print('Error fetching employee records: $e');
      throw e; // Optionally rethrow the exception for upper layers to handle
    }
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    print("Month-Year Picker Opened");

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int selectedYear =
        selectedMonth.year; // Start with the current selected year

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Select Month & Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'NexaBold',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_left, color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear--; // Decrease year
                            });
                          },
                        ),
                        Text(
                          '$selectedYear',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_right, color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear++; // Increase year
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                height: screenHeight * 0.4,
                width: screenWidth * 0.8,
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (BuildContext context, int index) {
                    final month = DateTime(selectedYear, index + 1);
                    return ListTile(
                      title: Text(
                        '${_getMonthName(month.month)} $selectedYear',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(month);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(DateTime(selectedYear, selectedMonth.month));
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  String _getMonthName(int month) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(employeeId: widget.employeeId),
      // drawer: MyDrawer(employeeId: widget.employeeId),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.02,
                left: MediaQuery.of(context).size.width * 0.02,
                right: MediaQuery.of(context).size.width * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "My Attendance",
                    style: TextStyle(
                        fontFamily: "NexaBold",
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.01),
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.01,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      _showMonthYearPicker(context);
                    },
                    child: Text(
                      "Pick a Month",
                      style: TextStyle(
                        color: primary,
                        fontFamily: "NexaBold",
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.65,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchEmployeeRecordsFromAPI(
                    widget.employeeId, selectedMonth),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final records = snapshot.data!;
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final recordDate = record['checkIn'] != null
                            ? DateTime.parse(record['checkIn'])
                            : DateTime(1970); // Default date if null

                        if (recordDate.month == selectedMonth.month &&
                            recordDate.year == selectedMonth.year) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.height * 0.01,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.02,
                            ),
                            height: MediaQuery.of(context).size.height * 0.1,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        record['checkIn'] != null
                                            ? DateFormat('EE\ndd')
                                                .format(recordDate)
                                            : "--\n--",
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Check In",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        record['checkIn'] != null &&
                                                record['checkIn'] is String
                                            ? DateFormat.Hm().format(
                                                DateTime.parse(
                                                    record['checkIn']))
                                            : "--:--",
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Check Out",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        record['checkOut'] != null &&
                                                record['checkOut'] is String
                                            ? DateFormat.Hm().format(
                                                DateTime.parse(
                                                    record['checkOut']))
                                            : "--:--",
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return SizedBox();
                        }
                      },
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
