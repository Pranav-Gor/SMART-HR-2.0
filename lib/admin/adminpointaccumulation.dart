import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';

class AdminPointAccumulation extends StatefulWidget {
  const AdminPointAccumulation({super.key});

  @override
  State<AdminPointAccumulation> createState() => _AdminPointAccumulationState();
}

class _AdminPointAccumulationState extends State<AdminPointAccumulation> {
  Color primary = const Color(0xffeef444c);
  final TextEditingController performancePointsController =
      TextEditingController();
  final TextEditingController attendancePointsController =
      TextEditingController();
  final TextEditingController seminarPointsController = TextEditingController();

  String? selecteduserID;
  List<Map<String, dynamic>> employee = [];
  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  @override
  void dispose() {
    performancePointsController.dispose();
    attendancePointsController.dispose();
    seminarPointsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.29.211/hr_api/get_employees.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && !data.contains('error')) {
          setState(() {
            employee = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          showSnackBar('No employees found');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showSnackBar('Failed to fetch employees');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar('Error fetching employees: $e');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveData() async {
    if (!validateInputs()) return;

    try {
      final response = await submitData();
      handleSaveResponse(response);
    } catch (e) {
      showSnackBar('Error occurred!');
    }
  }

  bool validateInputs() {
    if (selecteduserID == null ||
        performancePointsController.text.isEmpty ||
        attendancePointsController.text.isEmpty ||
        seminarPointsController.text.isEmpty) {
      showSnackBar('Please fill all fields and select an employee!');
      return false;
    }
    return true;
  }

  Future<http.Response> submitData() async {
    final int performancePoints = int.parse(performancePointsController.text);
    final int attendancePoints = int.parse(attendancePointsController.text);
    final int seminarPoints = int.parse(seminarPointsController.text);

    final url = Uri.parse(
        'http://192.168.29.211/hr_api/point.php'); // Your PHP API URL

    final body = jsonEncode({
      'userID': selecteduserID,
      'performancePoints': performancePoints,
      'attendancePoints': attendancePoints,
      'seminarPoints': seminarPoints,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    return response;
  }

  void handleSaveResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['success'] == true) {
        showSnackBar('Data saved successfully');
        clearFields();
      } else {
        showSnackBar('Failed to save data: ${responseBody['message']}');
      }
    } else {
      showSnackBar('Failed to save data. Please try again later.');
    }
  }

  void clearFields() {
    setState(() {
      selecteduserID = null;
      attendancePointsController.text = "";
      performancePointsController.text = "";
      seminarPointsController.text = "";
    });
  }

  Widget buildPointsContainer({
    required String title,
    required String imagePath,
    required TextEditingController controller,
  }) {
    return Container(
      height: 100.0,
      width: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black87.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                height: 100.0,
                width: 140.0,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: "NexaBold",
                  ),
                ),
                const SizedBox(height: 3.0),
                SizedBox(
                  height: 40,
                  width: 150.0,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    cursorColor: Colors.red,
                    decoration: InputDecoration(
                      hintText: 'Enter points',
                      hintStyle: const TextStyle(
                          fontFamily: 'NexaRegular', color: Colors.black),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8.0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 12.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmployeeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        width: 400,
        height: 60,
        margin: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select employee',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    items: employee.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['userID'].toString(),
                        child: Text(employee['firstName'] ?? ''),
                      );
                    }).toList(),
                    value: selecteduserID,
                    onChanged: (String? newValue) {
                      setState(() {
                        selecteduserID = newValue;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 50,
                      width: 250,
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                      offset: const Offset(0, -5),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                      padding: EdgeInsets.only(
                        left: 14,
                        right: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSaveButton() {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.2),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(3, 3),
        )
      ]),
      margin: const EdgeInsets.only(
        top: 10,
        bottom: 20,
        left: 15,
        right: 15,
      ),
      child: ElevatedButton(
        onPressed: saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Save',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'NexaRegular',
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Points Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NexaBold',
          ),
        ),
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(1.0),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  height: 210,
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/myrwd.jpg',
                      width: 200,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                buildEmployeeDropdown(),
                const SizedBox(height: 16.0),
                buildPointsContainer(
                  title: 'Performance Points:',
                  imagePath: 'assets/images/vecv2.jpg',
                  controller: performancePointsController,
                ),
                const SizedBox(height: 20.0),
                buildPointsContainer(
                  title: 'Attendance Points:',
                  imagePath: 'assets/images/att3.png',
                  controller: attendancePointsController,
                ),
                const SizedBox(height: 20.0),
                buildPointsContainer(
                  title: 'Seminar Points:',
                  imagePath: 'assets/images/inn1.jpg',
                  controller: seminarPointsController,
                ),
                const SizedBox(height: 10),
                buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
