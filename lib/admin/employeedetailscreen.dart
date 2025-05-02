import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class employeedetails extends StatefulWidget {
  final String employeeId;

  employeedetails({required this.employeeId});

  @override
  _employeedetailsState createState() => _employeedetailsState();
}

class _employeedetailsState extends State<employeedetails> {
  final Color primary = const Color(0xffeef444c);
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _jobtitle = TextEditingController();
  DateTime? _selectedDate;
  Uint8List? profilePicBytes;
  String? profilePicLink;
  String mobileno = "";
  String point = "";
  String id = "";

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);

        // Find the employee with the matching user ID
        final employeeData = employeeList.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeeData == null) {
          throw Exception(
              'Employee data not found for user ID: ${widget.employeeId}');
        }

        // Extract employee details
        final String firstName = employeeData['firstName'] ?? '';
        final String lastName = employeeData['lastName'] ?? '';
        final String gender = employeeData['gender'] ?? '';
        final String address = employeeData['address'] ?? '';
        final String mobile = employeeData['contactNumber'] ?? '';
        final String points = employeeData['points'] ?? '';
        final String dob = employeeData['birthdate'] ?? '';
        final String department = employeeData['deptName'] ?? '';
        final String jobtitle = employeeData['title'] ?? '';
        final String _id = employeeData['userID'] ?? '';
        DateTime? dobDateTime;
        String formattedDob = '';

        if (dob.isNotEmpty) {
          dobDateTime = DateTime.parse(dob);
          formattedDob = DateFormat('dd/MM/yyyy').format(dobDateTime);
          _selectedDate = dobDateTime;
        }

        final profilePic = employeeData['photo'];
        if (profilePic != null && profilePic.isNotEmpty) {
          profilePicBytes = base64Decode(profilePic);
        }

        // Update the state with employee data
        setState(() {
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
          _genderController.text = gender;
          _addressController.text = address;
          _dobController.text = formattedDob;
          _department.text = department;
          _jobtitle.text = jobtitle;
          mobileno = mobile;
          point = points;
          id = _id;
          // Update other state variables if needed
          profilePicLink =
              profilePicBytes != null ? base64Encode(profilePicBytes!) : "";
        });
        print("points: $points");
      } else {
        throw Exception(
            'Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employee data: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Details',
          style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () {
                  if (profilePicBytes != null) {
                    _showImageDialog(context, profilePicBytes!);
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 60,
                  child: profilePicBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            profilePicBytes!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.black26,
                          size: 55,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              title: 'Personal Information',
              children: [
                // Center the profile picture and make it clickable:

                _buildInfoRow(Icons.person, 'Name',
                    '${_firstNameController.text} ${_lastNameController.text}'),
                _buildInfoRow(
                  _genderController.text == 'Male'
                      ? Icons.male
                      : _genderController.text == 'Female'
                          ? Icons.female
                          : Icons.transgender, // Default icon for other genders
                  'Gender',
                  _genderController.text,
                ),

                _buildInfoRow(Icons.cake, 'Date of Birth', _dobController.text),
                _buildInfoRow(Icons.phone, 'Contact Number', mobileno),
                _buildInfoRow(Icons.home, 'Address', _addressController.text),
                _buildInfoRow(Icons.work, 'Department', _department.text),
                _buildInfoRow(Icons.badge, 'Job Title', _jobtitle.text),
              ],
            ),
            const SizedBox(height: 5),
            _buildInfoCard(
              title: 'Skills & Languages',
              children: [
                _buildLanguagesSection(widget.employeeId),
                _buildSkillsSection(widget.employeeId),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: SizedBox(
                width: 400,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ReportSelectionScreen(employeeId: id)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Report',
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'NexaRegular',
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 7,
      color: Colors.white,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xffeef444c),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xffeef444c)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

// Function to show the image in a zoomable dialog
  void _showImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            // Use InteractiveViewer for zoom/pan
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.memory(imageBytes),
          ),
        );
      },
    );
  }
}

Widget _buildLanguagesSection(String employeeId) {
  return FutureBuilder<List<String>>(
    future: fetchLanguages(employeeId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text('Fetching languages...');
      }
      if (snapshot.hasError) {
        return Text('Error fetching languages: ${snapshot.error}');
      }

      final languages = snapshot.data ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.language,
                color: Colors.red,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Languages Known:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (languages.isNotEmpty)
            ListTile(
              title: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: languages
                    .asMap()
                    .entries
                    .map(
                      (e) => Text('${e.key + 1}. ${e.value}',
                          style: const TextStyle(fontSize: 16)),
                    )
                    .toList(),
              ),
            )
          else
            const Text('No languages known'),
        ],
      );
    },
  );
}

Future<List<String>> fetchLanguages(String employeeId) async {
  try {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/showskill.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Filter data where userid is equal to employeeId
      final List<dynamic> filteredData =
          data.where((entry) => entry['userID'] == employeeId).toList();

      // Extract languages from filtered data
      final List<String> languages =
          filteredData.map((e) => e['language'] as String).toList();

      return languages;
    } else {
      throw Exception('Failed to fetch languages: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error fetching languages: $e');
    throw Exception('Error fetching languages: $e');
  }
}

Widget _buildSkillsSection(String employeeId) {
  return FutureBuilder<List<String>>(
    future: fetchskill(employeeId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text('Fetching languages...');
      }
      if (snapshot.hasError) {
        return Text('Error fetching languages: ${snapshot.error}');
      }

      final languages = snapshot.data ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.code,
                color: Colors.red,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Skills:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (languages.isNotEmpty)
            ListTile(
              title: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: languages
                    .asMap()
                    .entries
                    .map(
                      (e) => Text('${e.key + 1}. ${e.value}',
                          style: const TextStyle(fontSize: 16)),
                    )
                    .toList(),
              ),
            )
          else
            const Text('No languages known'),
        ],
      );
    },
  );
}

Future<List<String>> fetchskill(String employeeId) async {
  try {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/showskill.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Filter data where userid is equal to employeeId
      final List<dynamic> filteredData =
          data.where((entry) => entry['userID'] == employeeId).toList();

      // Extract languages from filtered data
      final List<String> languages =
          filteredData.map((e) => e['skill'] as String).toList();

      return languages;
    } else {
      throw Exception('Failed to fetch languages: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error fetching languages: $e');
    throw Exception('Error fetching languages: $e');
  }
}

// Report Selection Screen
class ReportSelectionScreen extends StatelessWidget {
  final String employeeId;
  final Color primary = const Color(0xffeef444c);
  ReportSelectionScreen({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color of the back arrow here
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset('assets/edetails.json')),
            ),
            const SizedBox(height: 15),
            _buildReportButton(
              context,
              'View Attendance',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AttendanceScreen(employeeId: employeeId)),
              ),
            ),
            const SizedBox(height: 15),
            _buildReportButton(
              context,
              'Seminar Attendance',
              () {
                // Navigate to Leave Report screen (replace with your Leave Report screen)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SeminarAttendanceScreen(employeeId: employeeId)),
                );
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text("Leave Report - Coming Soon!")),
                // );
              },
            ),
            const SizedBox(height: 15),
            _buildReportButton(
              context,
              'Leave Report',
              () {
                // Navigate to Leave Report screen (replace with your Leave Report screen)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          LeaveReportScreen(employeeId: employeeId)),
                );
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text("Leave Report - Coming Soon!")),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(
      BuildContext context, String title, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9, // 80% of screen width
      height: 43,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 10, // Controls the shadow depth
          shadowColor: Colors.red, // Shadow color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NexaRegular',
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key, required this.employeeId})
      : super(key: key);
  final String employeeId;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late double screenHeight;
  late double screenWidth;

  Color primary = const Color(0xffeef444c);
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

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
                          icon:
                              const Icon(Icons.arrow_left, color: Colors.white),
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
                          icon: const Icon(Icons.arrow_right,
                              color: Colors.white),
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
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          'Attendance Report',
          style: TextStyle(fontFamily: 'NexaBold', color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color of the back arrow here
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 0, left: 90),
              child: Text(
                "My Attendance",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 5),
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth / 18,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 0,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () async {
                      _showMonthYearPicker(context);
                      print("ia click");
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
            const SizedBox(
              height: 50,
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

class LeaveReportScreen extends StatefulWidget {
  final String employeeId;

  const LeaveReportScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  _LeaveReportScreenState createState() => _LeaveReportScreenState();
}

class _LeaveReportScreenState extends State<LeaveReportScreen> {
  late double screenHeight;
  late double screenWidth;
  Color primary = const Color(0xffeef444c);
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> fetchEmployeeLeaveRecords(
      String employeeId, DateTime selectedMonth) async {
    final apiUrl = 'http://192.168.29.211/hr_api/showleave.php';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<Map<String, dynamic>> records = [];

        // Access 'data' field and filter leave records
        var data = jsonData['data'];
        for (var record in data) {
          if (record['userID'] != null &&
              record['userID'].toString() == employeeId) {
            if (record['startDate'] != null && record['endDate'] != null) {
              // Parse date strings to DateTime
              DateTime startDate = DateTime.parse(record['startDate']);
              DateTime endDate = DateTime.parse(record['endDate']);

              // Get the month and year as zero-padded strings
              String startMonth = startDate.month.toString().padLeft(2, '0');
              String endMonth = endDate.month.toString().padLeft(2, '0');
              String selectedMonthStr =
                  selectedMonth.month.toString().padLeft(2, '0');

              // Check if the selected month is within the leave period
              if (selectedMonthStr.compareTo(startMonth) >= 0 &&
                  selectedMonthStr.compareTo(endMonth) <= 0) {
                records.add(Map<String, dynamic>.from(record));
              }
            }
          }
        }
        print("leave:$records");
        return records;
      } else {
        throw Exception(
            'Failed to fetch leave records: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave records: $e');
      throw e;
    }
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int selectedYear = selectedMonth.year;

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
                          icon:
                              const Icon(Icons.arrow_left, color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear--;
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
                          icon: const Icon(Icons.arrow_right,
                              color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear++;
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
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(
          'Leave Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.05,
            fontFamily: "NexaBold",
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            Center(
              child: Text(
                "My Leave",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth * 0.055,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showMonthYearPicker(context),
                    child: Text(
                      "Pick a Month",
                      style: TextStyle(
                        color: primary,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              height: screenHeight * 0.65,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    fetchEmployeeLeaveRecords(widget.employeeId, selectedMonth),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final records = snapshot.data!;
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final startDate = DateTime.parse(record['startDate']);
                        final endDate = DateTime.parse(record['endDate']);
                        final difference =
                            endDate.difference(startDate).inDays + 1;

                        return Container(
                          margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.01,
                          ),
                          height: screenHeight * 0.17,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
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
                              // Start Date
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.02),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Start Date",
                                            style: TextStyle(
                                              fontFamily: "NexaRegular",
                                              fontSize: screenWidth * 0.03,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('EE\ndd')
                                                .format(startDate),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "NexaBold",
                                              fontSize: screenWidth * 0.045,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // End Date
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primary,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.02),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "End Date",
                                            style: TextStyle(
                                              fontFamily: "NexaRegular",
                                              fontSize: screenWidth * 0.03,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('EE\ndd')
                                                .format(endDate),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "NexaBold",
                                              fontSize: screenWidth * 0.045,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Leave Info
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.025),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Leave Type: ${record['leaveType']}",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        "Reason: ${record['reason']}",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: screenWidth * 0.037,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        "Duration: $difference days",
                                        style: TextStyle(
                                          fontFamily: "NexaRegular",
                                          fontSize: screenWidth * 0.037,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        "Status: ${record['status']}",
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: screenWidth * 0.04,
                                          color:
                                              _getStatusColor(record['status']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text(
                        "No leave records found for this month.",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black; // Default color
    }
  }
}

class SeminarAttendanceScreen extends StatefulWidget {
  final String employeeId;

  const SeminarAttendanceScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  _SeminarAttendanceScreenState createState() =>
      _SeminarAttendanceScreenState();
}

class _SeminarAttendanceScreenState extends State<SeminarAttendanceScreen> {
  late double screenHeight;
  late double screenWidth;
  Color primary = const Color(0xffeef444c);
  late DateTime selectedMonth;
  List<Map<String, dynamic>> seminarAttendanceData = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _fetchSeminarAttendance(); // Fetch data when the screen initializes
  }

  Future<void> _fetchSeminarAttendance() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.29.211/hr_api/showseminarattendance.php')); // Replace with your API endpoint

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<Map<String, dynamic>> fetchedData =
            List<Map<String, dynamic>>.from(jsonData);

        // Filter data by employeeId and selected month
        setState(() {
          seminarAttendanceData = fetchedData.where((record) {
            // Check if userID and attendanceDate are not null
            if (record['userID'] != null && record['attendanceDate'] != null) {
              return record['userID'].toString() == widget.employeeId &&
                  DateTime.parse(record['attendanceDate']).month ==
                      selectedMonth.month &&
                  DateTime.parse(record['attendanceDate']).year ==
                      selectedMonth.year;
            }
            return false; // If either is null, don't include the record.
          }).toList();
        });
      } else {
        // Show error message.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to load seminar attendance. Status code: ${response.statusCode}')));
      }
    } catch (e) {
      //Show error message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching seminar attendance: $e')));
    }
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int selectedYear = selectedMonth.year;

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
                          icon:
                              const Icon(Icons.arrow_left, color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear--;
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
                          icon: const Icon(Icons.arrow_right,
                              color: Colors.white),
                          onPressed: () {
                            setDialogState(() {
                              selectedYear++;
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

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
      });
      _fetchSeminarAttendance(); // Re-fetch data with the new month
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

  // Helper function to get seminar title from seminarID
// Update the _getSeminarTitle function to return both title and place
  Future<Map<String, String>> _getSeminarDetails(String seminarId) async {
    final apiUrl = 'http://192.168.29.211/hr_api/showseminar.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> seminars = json.decode(response.body);

        // Find the seminar with matching ID
        final seminar = seminars.firstWhere(
          (s) => s['seminarID'].toString() == seminarId,
          orElse: () => null,
        );

        if (seminar != null &&
            seminar['title'] != null &&
            seminar['place'] != null) {
          return {
            'title': seminar['title'],
            'place': seminar['place'],
          };
        } else {
          return {
            'title': 'Title not found',
            'place': 'Place not found',
          };
        }
      } else {
        return {
          'title': 'Error: ${response.statusCode}',
          'place': 'Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error fetching seminar details: $e');
      return {
        'title': 'Error: $e',
        'place': 'Error: $e',
      };
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey; // Unknown status
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          'Seminar Attendance',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 0, left: 50),
              child: Text(
                "My Seminar Attendance",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 5),
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth / 18,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 0,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () async {
                      _showMonthYearPicker(context);
                      print("ia click");
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
            const SizedBox(height: 50),
            Container(
              height: MediaQuery.of(context).size.height * 0.65,
              child: seminarAttendanceData.isEmpty
                  ? const Center(
                      child: Text("No seminar attendance records found."))
                  : ListView.builder(
                      itemCount: seminarAttendanceData.length,
                      itemBuilder: (context, index) {
                        final record = seminarAttendanceData[index];
                        final attendanceDate =
                            DateTime.parse(record['attendanceDate']);

                        return FutureBuilder<Map<String, String>>(
                          future: _getSeminarDetails(
                              record['seminarID'].toString()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Card(
                                  child: ListTile(
                                      title: Text(
                                          "Error loading seminar details")));
                            }

                            final seminarDetails = snapshot.data!;

                            return Container(
                              margin: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.02,
                              ),
                              height: MediaQuery.of(context).size.height *
                                  0.12, // Increased height
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
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
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                DateFormat('EE\ndd')
                                                    .format(attendanceDate),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: "NexaBold",
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.045,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            seminarDetails['title']!,
                                            style: TextStyle(
                                              fontFamily: "NexaBold",
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.045,
                                            ),
                                          ),
                                          Text(
                                            "Place: ${seminarDetails['place']}",
                                            style: TextStyle(
                                              fontFamily: "NexaRegular",
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.040,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            "Status: ${record['status']}",
                                            style: TextStyle(
                                              fontFamily: "NexaBold",
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.040,
                                              color: _getStatusColor(
                                                  record['status']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
