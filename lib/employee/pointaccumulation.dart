import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class pointaccumulation extends StatefulWidget {
  const pointaccumulation({Key? key, required this.employeeId})
      : super(key: key);

  final String employeeId;

  @override
  State<pointaccumulation> createState() => _PointAccumulationState();
}

class _PointAccumulationState extends State<pointaccumulation> {
  Color primary = const Color(0xFFE9444C); // Fixed color code
  Map<String, dynamic>? employeeData;
  late List<Map<String, dynamic>> pointsData = [];

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
    fetchEmployeePoints();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic>? empData = jsonData.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );
        if (empData != null) {
          setState(() {
            employeeData = empData;
          });
        }
      } else {
        print('Failed to fetch employee data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    }
  }

  Future<void> fetchEmployeePoints() async {
    try {
      final requestBody = jsonEncode({
        'userID': widget.employeeId.toString(),
      });

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/fetchpoints.php'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData.isNotEmpty) {
          setState(() {
            pointsData = List<Map<String, dynamic>>.from(decodedData);
          });
        }
      } else {
        print('Failed to fetch points data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching points data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Point Accumulation',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NexaBold',
          ),
        ),
        backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Points
            Container(
              height: screenHeight * 0.2,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50.0),
                    bottomRight: Radius.circular(50.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 7,
                      blurRadius: 7,
                      offset: const Offset(1, 1),
                    ),
                  ]),
              child: pointsData.isNotEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${pointsData[0]['totalPoints']}',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              fontSize: screenWidth * 0.07,
                              color: primary,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Flexible(
                          child: Text(
                            'You gained ${pointsData[0]['totalPoints']} points this month',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'NexaRegular',
                              fontSize: screenWidth * 0.04,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Points Cards Section
            if (pointsData.isNotEmpty) ...[
              _buildPointsInfoCard(
                'Performance Points',
                'You get ${pointsData[0]['performancePoints']} points for achieving specific goals and meeting targets.',
                'assets/images/vecv2.jpg',
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildPointsInfoCard(
                'Attendance Points',
                'You get ${pointsData[0]['attendancePoints']} points for achieving attendance.',
                'assets/images/att3.png',
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildPointsInfoCard(
                'Seminar Points',
                'You get ${pointsData[0]['seminarPoints']} points for contributing innovation ideas.',
                'assets/images/inn1.jpg',
              ),
            ],

            if (pointsData.isEmpty)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsInfoCard(
      String title, String description, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 150.0,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: Image.asset(
                  imagePath,
                  height: 100.0,
                  width: 150.0,
                  fit: BoxFit.fitWidth,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: "NexaBold",
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: "NexaRegular",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
