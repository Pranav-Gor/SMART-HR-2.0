import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class redeemrewards extends StatefulWidget {
  const redeemrewards({Key? key, required this.employeeId}) : super(key: key);

  final String employeeId;

  @override
  State<redeemrewards> createState() => _redeemrewardsState();
}

class _redeemrewardsState extends State<redeemrewards> {
  late Future<Map<String, dynamic>> _employeeData;
  late Future<Map<String, dynamic>> _employeePoint;
  final Color primaryColor = const Color(0xFFE9444C);
  final Color secondaryColor = const Color(0xFFF5F5F5);
  final Color accentColor = const Color(0xFF4CAF50);
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  String firstName = "";

  @override
  void initState() {
    super.initState();
    _employeeData = fetchEmployeeData();
    _employeePoint = fetchEmployeePoints();
  }

  Future<Map<String, dynamic>> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);

        final employeeData = employeeList.firstWhere(
              (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeeData == null) {
          throw Exception(
              'Employee data not found for user ID: ${widget.employeeId}');
        }

        final profilePic = employeeData['photo'];
        final String? userFirstName =
        employeeData['firstName']; // Fetch first name from API

        if (profilePic != null && profilePic.isNotEmpty) {
          profilePicBytes = base64Decode(profilePic);
        }

        setState(() {
          profilePicLink =
          profilePicBytes != null ? base64Encode(profilePicBytes!) : "";
          firstName = userFirstName ?? ""; // Update first name
        });
        return employeeData;
      } else {
        throw Exception(
            'Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employee data: $e')),
      );
      return {}; // Return an empty map in case of error
    }
  }

  Future<Map<String, dynamic>> fetchEmployeePoints() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/cashoutpoint.php'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic>? employeePoint = jsonData.firstWhere(
              (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeePoint != null) {
          return employeePoint;
        } else {
          print('Employee with ID ${widget.employeeId} not found');
          return {}; // Return an empty map if employee not found
        }
      } else {
        print('Failed to fetch points data: ${response.reasonPhrase}');
        return {}; // Return an empty map if request fails
      }
    } catch (e) {
      print('Error fetching points data: $e');
      return {}; // Return an empty map in case of exception
    }
  }

  Future<void> cashOutPoints(Map<String, dynamic> employeeData) async {
    try {
      final employeePoint = await _employeePoint;

      int performancePoint =
          int.tryParse(employeePoint['performancePoints']?.toString() ?? '0') ??
              0;
      int seminarPoint =
          int.tryParse(employeePoint['seminarPoints']?.toString() ?? '0') ?? 0;
      int attendancePoints =
          int.tryParse(employeePoint['attendancePoints']?.toString() ?? '0') ??
              0;
      int totalPoints =
          (performancePoint + seminarPoint + attendancePoints) ~/ 10;

      final requestBody = jsonEncode({
        'userID': widget.employeeId.toString(),
        'cashout': totalPoints.toString(),
      });

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/updatepoints.php'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // setState(() { //No need to set state here as you are refetching employeeData
          //   employeeData['totalPoints'] = totalPoints;
          // });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Points cashed out successfully!')),
          );
          await resetPoints();
          //Refetch the data after successful cashout
          setState(() {
            _employeeData = fetchEmployeeData();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cash out points.')),
          );
        }
      } else {
        print('Failed to update points: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error updating points: $e');
    }
  }

  Future<void> resetPoints() async {
    try {
      final requestBody = jsonEncode({
        'userID': widget.employeeId.toString(),
      });

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/updatecashout.php'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Points reset successfully!')),
          );
          setState(() {
            _employeePoint = fetchEmployeePoints();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to reset points: ${result['error']}')),
          );
        }
      } else {
        print('Failed to reset points: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error resetting points: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting points: $e')),
      );
    }
  }

  void _showImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.memory(imageBytes, fit: BoxFit.contain),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Redeem Rewards',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NexaRegular',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _employeeData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                        child:
                        Icon(Icons.error, color: Colors.white, size: 50));
                  }

                  final employeeData = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                              radius: 40,
                              child: profilePicBytes != null
                                  ? ClipOval(
                                child: Image.memory(
                                  profilePicBytes!,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
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
                        const SizedBox(height: 15),
                        Text(
                          'Welcome, ${firstName}!', // Use firstName here
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Redeem your rewards points',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Points Summary Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      )
                    ]),
                child: Card(
                  elevation: 5,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _employeePoint,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                              child: Text('Error loading points'));
                        }

                        final employeePoint = snapshot.data!;
                        final int seminarPoint = int.tryParse(
                            employeePoint['seminarPoints'].toString()) ??
                            0;
                        final int performancePoint = int.tryParse(
                            employeePoint['performancePoints']
                                .toString()) ??
                            0;
                        final int attendancePoints = int.tryParse(
                            employeePoint['attendancePoints'].toString()) ??
                            0;
                        final int totalPoints = (performancePoint +
                            seminarPoint +
                            attendancePoints) ~/
                            10;

                        return Column(
                          children: [
                            const Text(
                              'YOUR POINTS SUMMARY',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildPointsItem('Performance Points',
                                performancePoint.toString(), Icons.star),
                            const Divider(height: 30),
                            _buildPointsItem('Seminar Points',
                                seminarPoint.toString(), Icons.school),
                            const Divider(height: 30),
                            _buildPointsItem(
                                'Attendance Points',
                                attendancePoints.toString(),
                                Icons.calendar_today),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Redeemable:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '$totalPoints ₹',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Cashout Section
// Cashout Section - Improved Version
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _employeePoint,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Unable to load points data',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final employeePoint = snapshot.data!;
              final int seminarPoint = int.tryParse(employeePoint['seminarPoints']?.toString() ?? '0') ?? 0;
              final int performancePoint = int.tryParse(employeePoint['performancePoints']?.toString() ?? '0') ?? 0;
              final int attendancePoints = int.tryParse(employeePoint['attendancePoints']?.toString() ?? '0') ?? 0;
              final int totalPoints = (performancePoint + seminarPoint + attendancePoints) ~/ 10;

              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      )
                    ]),
                child: Card(
                  elevation: 7,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.currency_rupee_rounded,
                            size: 50, color: Colors.amber),
                        const SizedBox(height: 15),
                        Text(
                          totalPoints > 0
                              ? 'You have $totalPoints redeemable points'
                              : 'No points available for redemption',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: totalPoints > 0 ? Colors.green : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          totalPoints > 0
                              ? '₹$totalPoints will be added to your salary'
                              : 'Attend more events to earn points',
                          style: TextStyle(
                            fontSize: 14,
                            color: totalPoints > 0 ? Colors.black87 : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: totalPoints > 0
                                ? () async {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Cash Out'),
                                  content: Text(
                                      'Are you sure you want to cash out $totalPoints points (₹$totalPoints)?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await cashOutPoints(employeePoint);
                                // Refresh data after cashout
                                setState(() {
                                  _employeePoint = fetchEmployeePoints();
                                });
                              }
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: totalPoints > 0 ? Colors.red : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              totalPoints > 0 ? 'CASH OUT NOW' : 'NO POINTS TO CASH OUT',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Points will be reset after cash out',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (totalPoints > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            '1 point = ₹1 (10 reward points = ₹1)',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
