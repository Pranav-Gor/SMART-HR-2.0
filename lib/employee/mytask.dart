import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/employee/leavescreen.dart';
import 'package:smart_hr/employee/myrewards.dart';
import 'package:smart_hr/employee/projectdetailsscreen.dart';
import 'package:smart_hr/employee/salarydatascreen.dart';
import 'package:smart_hr/employee/traindevscreen.dart';
import 'package:smart_hr/loginpage.dart';
import 'package:smart_hr/employee/employeedrawer.dart';

class mytask extends StatefulWidget {
  final String employeeId;

  const mytask({super.key, required this.employeeId});

  @override
  State<mytask> createState() => _mytaskState();
}

class _mytaskState extends State<mytask> {
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  static const Color primary = Color(0xffeef444c);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchProjectsStream();
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

  Stream<List<dynamic>> fetchProjectsStream() async* {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/showproject.php'));

    if (response.statusCode == 200) {
      final List<dynamic> projects = json.decode(response.body);
      yield projects;
    } else {
      throw Exception('Failed to load projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontFamily: 'NexaRegular',
            color: Colors.white,
          ),
        ),
        backgroundColor: primary, // Use primary color
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      // drawer: MyDrawer(employeeId: widget.employeeId),
      drawer: MyDrawer(
        employeeId: widget.employeeId,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/mtask.jpg',
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            const Text(
              'Projects you are involved in',
              style: TextStyle(
                fontFamily: 'NexaBold',
                fontSize: 18.0,
              ),
            ),
            const Divider(),
            StreamBuilder(
              stream: fetchProjectsStream(),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final projects = snapshot.data;

                return SingleChildScrollView(
                  child: Container(
                    width: 400,
                    height: 470,
                    child: ListView.builder(
                      itemCount: projects!.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  12), // Optional: Add border radius for rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                      0.4), // Use primary color with opacity
                                  spreadRadius: 1, // Spread radius
                                  blurRadius: 7, // Blur radius
                                  offset: const Offset(
                                      4, 5), // Offset in x and y directions
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () async {
                                // Fetch tasks for the project to determine employee type
                                String employeeType =
                                    await determineEmployeeType(
                                        project['projectID'],
                                        widget.employeeId);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectDetailScreen(
                                      projectid: project['projectID'],
                                      projectName: project['projectTitle'],
                                      employeeId: widget.employeeId,
                                      employeeType:
                                          employeeType, // Pass the determined employee type
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment
                                    .bottomRight, // Align the arrow to bottom-right
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project['projectTitle'],
                                              style: const TextStyle(
                                                fontSize: 18.0,
                                                fontFamily: "NexaRegular",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Add more project details if needed
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey,
                                      size:
                                          24, // Adjust the size of the arrow as needed
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to determine the employee type based on the project's tasks
  Future<String> determineEmployeeType(
      String projectID, String employeeId) async {
    final response = await http.get(
      Uri.parse('http://192.168.29.211/hr_api/showtask.php'),
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);

      if (responseData is List) {
        final List<dynamic> tasks = responseData;

        // Filter tasks based on userID and projectID
        final filteredTasks = tasks.where((task) {
          return task['userID'].toString() == employeeId &&
              task['projectID'].toString() == projectID;
        }).toList();

        // Check if any of the tasks have a non-null and non-empty address
        bool hasAddress = filteredTasks.any((task) =>
            task['address'] != null && task['address'].toString().isNotEmpty);

        // Return 'onfield' if there's an address, otherwise 'office'
        return hasAddress ? 'onfield' : 'office';
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load tasks');
    }
  }
}
