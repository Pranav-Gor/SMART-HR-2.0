import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
import 'package:dropdown_button2/dropdown_button2.dart';

import 'employeedrawer.dart';

class profilescreen extends StatefulWidget {
  const profilescreen({Key? key, required this.employeeId}) : super(key: key);
  final String employeeId;

  @override
  State<profilescreen> createState() => _profilescreenState();
}

class _profilescreenState extends State<profilescreen> {
  final Color primary = const Color(0xffeef444c);

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isEditing = false;
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  File? _photo;

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        final Map<String, dynamic>? employeeData = jsonData.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeeData != null) {
          final firstName = employeeData['firstName'] ?? '';
          final lastName = employeeData['lastName'] ?? '';
          final address = employeeData['address'] ?? '';
          final dob = employeeData['birthdate'] ?? '';

          final dobDateTime = DateTime.tryParse(dob);
          final formattedDob = dobDateTime != null
              ? DateFormat('dd/MM/yyyy').format(dobDateTime)
              : '';

          final profilePic = employeeData['photo'] ?? '';

          if (profilePic.isNotEmpty) {
            try {
              profilePicBytes = base64Decode(profilePic);
            } catch (e) {
              print('Error decoding base64 profile picture: $e');
            }
          }

          setState(() {
            _firstNameController.text = firstName;
            _lastNameController.text = lastName;
            _addressController.text = address;
            _dobController.text = formattedDob;
            _selectedDate = dobDateTime;
            if (profilePicBytes != null) {
              profilePicLink = base64Encode(profilePicBytes!);
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickprofile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      _photo = File(result.files.single.path!);
      List<int> imageBytes = await _photo!.readAsBytes();
      setState(() {
        profilePicBytes = Uint8List.fromList(imageBytes);
        profilePicLink = base64Encode(profilePicBytes!);
      });
    }
  }

  Future<void> submitForm() async {
    if (_firstNameController.text.isEmpty &&
        _lastNameController.text.isEmpty &&
        _addressController.text.isEmpty &&
        _selectedDate == null &&
        _photo == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please update at least one field!'),
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

    Map<String, dynamic> requestBody = {
      'userID': widget.employeeId,
    };

    if (_firstNameController.text.isNotEmpty) {
      requestBody['firstName'] = _firstNameController.text;
    }
    if (_lastNameController.text.isNotEmpty) {
      requestBody['lastName'] = _lastNameController.text;
    }
    if (_addressController.text.isNotEmpty) {
      requestBody['address'] = _addressController.text;
    }
    if (_selectedDate != null) {
      requestBody['birthdate'] = _selectedDate!.toIso8601String();
    }

    if (_photo != null) {
      List<int> imageBytes = await _photo!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      base64Image = fixBase64(base64Image);
      requestBody['photo'] = base64Image;
    } else if (profilePicBytes != null) {
      requestBody['photo'] = base64Encode(profilePicBytes!);
    } else {
      requestBody['photo'] = '';
    }

    final apiUrl = 'http://192.168.29.211/hr_api/updateprofile.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Profile updated successfully!'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Error updating data: $e");
    }
  }

  String fixBase64(String base64String) {
    while (base64String.length % 4 != 0) {
      base64String += '=';
    }
    return base64String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Profile Picture Section
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  onPressed: () {
                    if (_isEditing) {
                      submitForm(); // Submit the form
                      setState(() {
                        _isEditing = false; // Switch back to edit mode
                      });
                    } else {
                      setState(() {
                        _isEditing = true; // Switch to editing mode
                      });
                    }
                  },
                ),
              ],
            ),
            Container(
              height: 160,
              width: 400,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickprofile : null,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 120,
                            height: 120,
                            color: primary.withOpacity(0.1),
                            child: profilePicBytes != null
                                ? Image.memory(
                                    profilePicBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: primary,
                                  ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Employee ID: ${widget.employeeId}",
                    style: const TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Personal Information Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "NexaBold",
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // First Name
                  const Text(
                    'First Name:',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "NexaRegular",
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              enabled: _isEditing,
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter first name",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Last Name
                  const Text(
                    'Last Name:',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "NexaRegular",
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              enabled: _isEditing,
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter last name",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Date of Birth
                  const Text(
                    'Date of Birth:',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "NexaRegular",
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: _isEditing ? () => _selectDate(context) : null,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.red),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedDate!)
                                  : "Select date of birth",
                              style: TextStyle(
                                color: _isEditing ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Address
                  const Text(
                    'Address:',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "NexaRegular",
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              enabled: _isEditing,
                              controller: _addressController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter your address",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Update Button (only shown in edit mode)
            if (_isEditing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                height: 48,
                child: ElevatedButton(
                  onPressed: submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 7,
                    shadowColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'NexaRegular',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
