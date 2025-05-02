import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/employee/leavescreen.dart';
import 'package:smart_hr/employee/myrewards.dart';
import 'package:smart_hr/employee/mytask.dart';
import 'package:smart_hr/employee/salarydatascreen.dart';
import 'package:smart_hr/loginpage.dart';
import 'employeedrawer.dart';

class traindevscreen extends StatefulWidget {
  const traindevscreen({Key? key, required this.employeeId}) : super(key: key);
  final String employeeId;
  @override
  State<traindevscreen> createState() => _traindevscreenState();
}

class _traindevscreenState extends State<traindevscreen> {
  final Color primary = const Color(0xffeef444c);
  bool isAttended = false;
  String _selectedItem = 'AI assistance'; // Initialize selected item
  DateTime? _selectedDate; // Define _selectedDate variable here
  DateTime? _selectedEndDate;
  BuildContext? scaffoldContext;
  List<List<String>> skillsData = [];
  List<List<String>> languagesData = [];
  List<Map<String, dynamic>> seminarList = [];
  Uint8List? profilePicBytes;
  String? profilePicLink;
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController languagesController = TextEditingController();
  Map<String, bool> attendedSeminars = {};

  @override
  void initState() {
    super.initState();
    fetchSkillsData();
    fetchLanguagesData();
    _fetchData();
    fetchEmployeeData();
    fetchAttendedSeminars(); // Add this line
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

  Future<void> Addpoint(String userId) async {
    if (userId.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.29.211/hr_api/seminarpoint.php'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'userID': userId, // Correct parameter name to match PHP
          },
        );

        print(response.body); // Debugging response

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seminar points updated successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to update seminar points: ${responseData['message']}'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to connect: ${response.statusCode}')),
          );
        }
      } catch (e) {
        print('Error occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the employee ID!')),
      );
    }
  }

  Future<void> addseminar(String seminarId, String title) async {
    final String userid = widget.employeeId;

    if (userid.isNotEmpty && seminarId.isNotEmpty && title.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.29.211/hr_api/addseminar_attendance.php'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'userID': userid,
            'seminarID': seminarId,
            'attendanceDate': DateTime.now().toIso8601String(),
            'status': 'attended'
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['success']) {
            // Update local state immediately
            setState(() {
              attendedSeminars[seminarId] = true;
            });

            // Add points
            await Addpoint(userid);

            // Refresh the seminar list
            await fetchAttendedSeminars();

            // Remove the attended seminar from the list
            setState(() {
              seminarList.removeWhere(
                      (seminar) => seminar['seminarID'].toString() == seminarId);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Attendance marked successfully!')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${responseData['message']}')),
              );
            }
          }
        }
      } catch (e) {
        print('Error occurred: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    try {
      // Fetch all seminars
      final response = await http.get(
        Uri.parse('http://192.168.29.211/hr_api/showseminar.php'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final dynamic decodedData = json.decode(response.body);
        List<Map<String, dynamic>> seminarList = [];

        // Handle both array and object responses
        if (decodedData is List) {
          seminarList = List<Map<String, dynamic>>.from(decodedData);
        } else if (decodedData is Map) {
          if (decodedData.containsKey('seminars')) {
            final seminarsData = decodedData['seminars'];
            if (seminarsData is List) {
              seminarList = List<Map<String, dynamic>>.from(seminarsData);
            }
          } else {
            seminarList = [Map<String, dynamic>.from(decodedData)];
          }
        }

        return seminarList; // Return the fetched seminar list
      } else {
        throw Exception('Failed to fetch data or empty response');
      }
    } catch (e) {
      print('Error fetching seminar data: $e');
      return []; // Return empty list instead of throwing exception
    }
  }

  Future<void> fetchLanguagesData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showskill.php'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Filter employee data by user ID
        final List<dynamic> employeeDataList = jsonData
            .where(
              (employee) => employee['userID'] == widget.employeeId,
        )
            .toList();

        if (employeeDataList.isNotEmpty) {
          // Extract skills data for each employee
          List<List<String>> allSkillsData = [];
          for (var employeeData in employeeDataList) {
            final skills = employeeData['language'];
            if (skills != null && skills.isNotEmpty) {
              allSkillsData.add(
                  skills.split(',')); // Assuming skills are comma-separated
            } else {
              print(
                  'No skills found for employee with ID ${employeeData['userID']}');
            }
          }
          setState(() {
            languagesData = allSkillsData.cast<List<String>>();
          });
        } else {
          print('No employees found with ID ${widget.employeeId}');
        }
      } else {
        print('Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    }
  }

  Future<void> fetchSkillsData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showskill.php'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Filter employee data by user ID
        final List<dynamic> employeeDataList = jsonData
            .where(
              (employee) => employee['userID'] == widget.employeeId,
        )
            .toList();

        if (employeeDataList.isNotEmpty) {
          // Extract skills data for each employee
          List<List<String>> allSkillsData = [];
          for (var employeeData in employeeDataList) {
            final skills = employeeData['skill'];
            if (skills != null && skills.isNotEmpty) {
              allSkillsData.add(
                  skills.split(',')); // Assuming skills are comma-separated
            } else {
              print(
                  'No skills found for employee with ID ${employeeData['userID']}');
            }
          }
          setState(() {
            skillsData = allSkillsData.cast<List<String>>();
          });
        } else {
          print('No employees found with ID ${widget.employeeId}');
        }
      } else {
        print('Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    return picked;
  }


  Future<void> submitForm() async {
    if (!mounted) return;

    if (skillsController.text.isEmpty ||
        languagesController.text.isEmpty ||
        _selectedItem.isEmpty ||
        _selectedDate == null ||
        _selectedEndDate == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter all the required fields!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    final apiUrl = 'http://192.168.29.211/hr_api/addskill.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'}, // Ensure JSON format
        body: jsonEncode({
          'userID': widget.employeeId,
          'skill': skillsController.text,
          'language': languagesController.text, // Corrected key name
          'reference': _selectedItem,
          'startDate': _selectedDate!.toIso8601String(),
          'endDate': _selectedEndDate!.toIso8601String(),
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success']) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Data saved successfully'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        // Clear input fields
        skillsController.clear();
        languagesController.clear();
        print('Data saved successfully');
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      print("Error submitting form: $e");

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to submit form.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> fetchAttendedSeminars() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/get_attended_seminars.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userID': widget.employeeId,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // Handle different response formats
        if (decodedData is List) {
          // If response is already a list
          setState(() {
            for (var seminar in decodedData) {
              if (seminar is Map && seminar.containsKey('seminarID')) {
                attendedSeminars[seminar['seminarID'].toString()] = true;
              }
            }
          });
        } else if (decodedData is Map) {
          // If response is an object
          if (decodedData.containsKey('seminars')) {
            // If seminars are nested under 'seminars' key
            final seminars = decodedData['seminars'];
            if (seminars is List) {
              setState(() {
                for (var seminar in seminars) {
                  if (seminar is Map && seminar.containsKey('seminarID')) {
                    attendedSeminars[seminar['seminarID'].toString()] = true;
                  }
                }
              });
            }
          } else if (decodedData.containsKey('success')) {
            // If it's a success/error response
            if (decodedData['success'] == true &&
                decodedData.containsKey('data')) {
              final seminars = decodedData['data'];
              if (seminars is List) {
                setState(() {
                  for (var seminar in seminars) {
                    if (seminar is Map && seminar.containsKey('seminarID')) {
                      attendedSeminars[seminar['seminarID'].toString()] = true;
                    }
                  }
                });
              }
            }
          }
        }
      } else {
        print('Failed to fetch attended seminars: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attended seminars: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Training & Development',
            style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
          ),
          backgroundColor: primary,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        drawer: MyDrawer(employeeId: widget.employeeId),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 200,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14)),
                      child: Image.asset(
                        'assets/images/newlg.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills :',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "NexaBold",
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(
                              height:
                              5.0), // Add some space between the text and the text field
                          Container(
                            width: 400,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 7,
                                  offset: const Offset(2, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    child: Icon(
                                      Icons.code_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      controller: skillsController,
                                      keyboardType: TextInputType.text,
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          border: InputBorder.none,
                                          hintText: "Enter Your Skills",
                                          hintStyle: TextStyle(
                                              color: Colors.grey[600])),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          const Text(
                            'Languages :',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "NexaBold",
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(
                              height:
                              5.0), // Add some space between the text and the text field
                          Container(
                            width: 400,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 7,
                                  offset: const Offset(2, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    child: Icon(
                                      Icons.language,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      controller: languagesController,
                                      keyboardType: TextInputType.text,
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          border: InputBorder.none,
                                          hintText: "Enter Your Languages",
                                          hintStyle: TextStyle(
                                              color: Colors.grey[600])),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reference resources:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "NexaBold",
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  DropdownButtonHideUnderline(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 1.0),
                                      child: DropdownButton2<String>(
                                        isExpanded: true,
                                        hint: const Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Select Item',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                //overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'AI assistance',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.assistant_photo,
                                                  color: Colors.blueGrey,
                                                ), // Icon for the first item
                                                SizedBox(
                                                    width:
                                                    8), // Add some space between icon and text
                                                Text('AI assistance'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Github',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.code,
                                                  color: Colors.black,
                                                ), // Icon for the second item
                                                SizedBox(
                                                    width:
                                                    8), // Add some space between icon and text
                                                Text('Github'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Youtube',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.video_library,
                                                  color: Colors.red,
                                                ), // Icon for the third item
                                                SizedBox(
                                                    width:
                                                    8), // Add some space between icon and text
                                                Text('Youtube'),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Online-template',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.web,
                                                  color: Colors.blue,
                                                ), // Icon for the fourth item
                                                SizedBox(
                                                    width:
                                                    8), // Add some space between icon and text
                                                Text('Online-template'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        value: _selectedItem,
                                        onChanged: (value) async {
                                          setState(() {
                                            _selectedItem =
                                            value!; // Update selected item
                                          });
                                        },
                                        buttonStyleData: ButtonStyleData(
                                          height: 50,
                                          width: 250,
                                          padding: const EdgeInsets.only(
                                              left: 15, right: 15),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                spreadRadius: 2,
                                                blurRadius: 7,
                                                offset: const Offset(2, 3),
                                              ),
                                            ],
                                            color: Colors.white,
                                          ),
                                          elevation: 2,
                                        ),
                                        iconStyleData: const IconStyleData(
                                          icon: Icon(
                                            Icons.arrow_circle_down_sharp,
                                          ),
                                          iconSize: 25,
                                          iconEnabledColor: Colors.black,
                                          iconDisabledColor: Colors.grey,
                                        ),
                                        dropdownStyleData: DropdownStyleData(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            color: Colors.white,
                                          ),
                                          offset: const Offset(0, -5),
                                        ),
                                        menuItemStyleData:
                                        const MenuItemStyleData(
                                          height: 40,
                                          padding: EdgeInsets.only(
                                            left: 14,
                                            right: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duration time:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "NexaBold",
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Starting date:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "NexaBold",
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(
                                              0.3), // Shadow color with opacity
                                          blurRadius:
                                          10, // Softness of the shadow
                                          spreadRadius:
                                          1, // How much the shadow spreads
                                          offset: Offset(3,
                                              4), // Position of the shadow (X, Y)
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        DateTime? startDate =
                                        await _selectDate(context);
                                        if (startDate != null) {
                                          setState(() {
                                            if (mounted) {
                                              // Update states here
                                              print("Select date");
                                              _selectedDate = startDate;
                                            }
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.red, // Background color
                                        foregroundColor: Colors.white,
                                        elevation: 5, // Text color// Elevation
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              14), // BorderRadius
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 13,
                                            horizontal: 15), // Padding
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 8),
                                          Text(
                                            'Select Date',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'NexaRegular',
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  _selectedDate != null
                                      ? Text(
                                    '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: "NexaBold",
                                      color: Colors.black,
                                    ),
                                  )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Ending date:    ', // Change 'Starting date' to 'End date'
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "NexaBold",
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(
                                              0.3), // Shadow color with opacity
                                          blurRadius:
                                          10, // Softness of the shadow
                                          spreadRadius:
                                          1, // How much the shadow spreads
                                          offset: Offset(3,
                                              4), // Position of the shadow (X, Y)
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        DateTime? startEndDate =
                                        await _selectDate(context);
                                        if (startEndDate != null) {
                                          setState(() {
                                            if (mounted) {
                                              print("enddate");
                                              // Update states here
                                              _selectedEndDate = startEndDate;
                                            }
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.red, // Background color
                                        foregroundColor: Colors.white,
                                        elevation: 5, // Text color// Elevation
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              14), // BorderRadius
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 13,
                                            horizontal: 15), // Padding
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 8),
                                          Text(
                                            'Select Date',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'NexaRegular',
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  _selectedEndDate !=
                                      null // Change _selectedDate to _selectedEndDate
                                      ? Text(
                                    '${_selectedEndDate!.day}-${_selectedEndDate!.month}-${_selectedEndDate!.year}',
                                    // Change _selectedDate to _selectedEndDate
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: "NexaBold",
                                      color: Colors.black,
                                    ),
                                  )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: 350,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        submitForm();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => traindevscreen(
                                employeeId: widget.employeeId,
                              )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 7, // Controls the shadow depth
                        shadowColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit',
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NexaRegular',
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
        Material(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20)),
                    child: Image.asset(
                      'assets/images/skills.png',
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.5,
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills known by you:',
                            style: TextStyle(
                              fontSize: 21,
                              fontFamily: "NexaBold",
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Skills:',
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: "NexaBold",
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              child: ListView.builder(
                                itemCount: skillsData.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    color: Colors.white,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 5),
                                        Text(
                                          "${index + 1}.",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: "NexaRegular",
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: skillsData[index]
                                              .map<Widget>((skill) {
                                            return Text(
                                              skill,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: "NexaRegular",
                                                color: Colors.black,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Languages:',
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: "NexaBold",
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              child: ListView.builder(
                                itemCount: languagesData.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    color: Colors.white,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 3),
                                        Text(
                                          "${index + 1}.",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: "NexaRegular",
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: languagesData[index]
                                              .map<Widget>((language) {
                                            return Text(
                                              language,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: "NexaRegular",
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
            SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: 400,
                      decoration: BoxDecoration(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                        child: Image.asset(
                          'assets/images/sem.png',
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          final seminars = snapshot.data ?? [];

                          final now = DateTime.now();
                          final upcomingSeminars = seminars.where((seminar) {
                            final seminarId = seminar['seminarID'];
                            if (seminarId == null) return false;

                            if (attendedSeminars[seminarId] == true)
                              return false;

                            try {
                              final date = seminar['date'];
                              if (date == null) return false;

                              DateTime seminarDate = DateTime.parse(date);
                              final isToday = seminarDate.year == now.year &&
                                  seminarDate.month == now.month &&
                                  seminarDate.day == now.day;
                              return isToday || seminarDate.isAfter(now);
                            } catch (e) {
                              print(
                                  "Invalid date format or null date for seminar ID $seminarId: ${seminar['date']}");
                              return false;
                            }
                          }).toList();

                          if (upcomingSeminars.isEmpty) {
                            return const Center(
                              child: Text(
                                'No upcoming seminars available',
                                style: TextStyle(
                                  fontFamily: 'NexaRegular',
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: upcomingSeminars.map((seminar) {
                              final title = seminar['title'] ?? 'No Title';
                              final place = seminar['place'] ?? 'No Location';
                              final date = seminar['date'] ?? 'No Date';
                              final seminarId = seminar['seminarID'];

                              DateTime? seminarDate;
                              try {
                                seminarDate = DateTime.parse(date);
                              } catch (e) {
                                print("Error parsing date: $e");
                              }

                              final isToday = seminarDate != null &&
                                  seminarDate.year == now.year &&
                                  seminarDate.month == now.month &&
                                  seminarDate.day == now.day;

                              return Container(
                                width: 350,
                                margin: const EdgeInsets.only(bottom: 10.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 3,
                                      blurRadius: 7,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title.toUpperCase(),
                                        style: const TextStyle(
                                            fontFamily: 'NexaBold',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        place,
                                        style: const TextStyle(
                                          fontFamily: 'NexaBold',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'Date: $date',
                                        style: const TextStyle(
                                          fontFamily: 'NexaRegular',
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Container(
                                        width: 150,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                  0.3), // Shadow color with opacity
                                              blurRadius:
                                              10, // Softness of the shadow
                                              spreadRadius:
                                              1, // How much the shadow spreads
                                              offset: Offset(3,
                                                  4), // Position of the shadow (X, Y)
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isToday &&
                                              !(attendedSeminars[
                                              seminarId] ??
                                                  false)
                                              ? () async {
                                            await addseminar(
                                                seminarId.toString(),
                                                title);
                                            // The setState is handled inside addseminar
                                          }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            Colors.red, // Background color
                                            foregroundColor: Colors.white,
                                            elevation:
                                            5, // Text color// Elevation
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  14), // BorderRadius
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13,
                                                horizontal: 15), // Padding
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(
                                                isToday
                                                    ? 'Mark Attended'
                                                    : 'Not Today',
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'NexaRegular',
                                                    fontWeight:
                                                    FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ]),
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: [
            Tab(
              icon: const Icon(
                  Icons.library_books), // Add icon for 'New learning'
              child: Container(
                child: const Text(
                  'New skill',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "NexaBold",
                    color: Colors.black,
                  ),
                ), // Add text for 'New learning'
              ),
            ),
            const Tab(
              icon: Icon(Icons.lightbulb_outline),
              child: Text(
                'Skills known',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                ),
              ), // Add icon for 'Skill known'
            ),
            const Tab(
              icon: Icon(Icons.event), // Add icon for 'Seminar&work-shop'
              child: Text(
                'Seminars',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                ),
              ),
            ),
          ],
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.all(5.0),
          indicatorColor: Colors.redAccent,
        ),
      ),
    );
  }
}
