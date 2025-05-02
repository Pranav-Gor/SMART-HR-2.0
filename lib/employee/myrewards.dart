import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_hr/employee/employeedrawer.dart';
import 'package:smart_hr/employee/pointaccumulation.dart';
import 'package:smart_hr/employee/redeemrewards.dart';

class MyReward extends StatefulWidget {
  const MyReward({Key? key, required this.employeeId}) : super(key: key);

  final String employeeId;

  @override
  _MyRewardState createState() => _MyRewardState();
}

class _MyRewardState extends State<MyReward> {
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    Color primary = const Color(0xffeef444c);
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Rewards',
            style: TextStyle(
              fontFamily: 'NexaRegular',
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          iconTheme: const IconThemeData(
            color: Colors.white, // Change this color to your desired color
          ),
        ),
        // drawer: MyDrawer(employeeId: widget.employeeId),
        drawer: MyDrawer(employeeId: widget.employeeId),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Image.asset(
              'assets/images/myrwd.jpg', // Replace with your image path
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
                              builder: (context) => pointaccumulation(
                                employeeId: widget.employeeId,
                              ),
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
                              'Point Accumulation',
                              style: TextStyle(
                                  fontSize: 16, fontFamily: 'NexaRegular'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Handle the button press for Container 1
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => redeemrewards(
                                  employeeId: widget.employeeId,
                                ),
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
                                vertical: 15, horizontal: 37), // Padding
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.redeem, color: Colors.yellow), // Icon
                              SizedBox(width: 8),
                              Text(
                                'Redeem Option',
                                style: TextStyle(
                                    fontSize: 16, fontFamily: 'NexaRegular'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ));
  }
}
