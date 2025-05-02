import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:dropdown_button2/dropdown_button2.dart'; // Make sure to add this dependency

import 'department.dart';

class JobTitleManagement extends StatefulWidget {
  const JobTitleManagement({super.key});

  @override
  State<JobTitleManagement> createState() => _JobTitleManagementState();
}

class _JobTitleManagementState extends State<JobTitleManagement> {
  final TextEditingController _jobTitleController = TextEditingController();
  String? _selectedDepartment;
  List<String> _departments = [];
  List<Map<String, String>> _jobTitles = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchJobTitles();
  }

  Future<void> _fetchJobTitles() async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/showjobtitle.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          setState(() {
            _jobTitles = jsonResponse.map((jobtitle) {
              return {
                'jobtitle': jobtitle['title'].toString(),
                'department': jobtitle['deptName'].toString(),
              };
            }).toList();
          });
        } else {
          print('Error: Expected a JSON array');
          _showSnackBar('Unexpected response format');
        }
      } else {
        print(
            'Error: Failed to fetch job titles. Status code: ${response.statusCode}');
        _showSnackBar('Failed to fetch job titles');
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error occurred while fetching job titles');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/showdept.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          setState(() {
            _departments = jsonResponse
                .map((dept) => dept['deptName'].toString())
                .toList();
          });
        } else {
          print('Error: Expected a JSON array');
          _showSnackBar('Unexpected response format');
        }
      } else {
        print(
            'Error: Failed to fetch departments. Status code: ${response.statusCode}');
        _showSnackBar('Failed to fetch departments');
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error occurred while fetching departments');
    }
  }

  Future<void> _addJobTitle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/addjobtitle.php');
      final response = await http.post(
        url,
        body: jsonEncode({
          'name': _jobTitleController.text.trim(),
          'department': _selectedDepartment!,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          _showSnackBar('Job Title added successfully');
          _jobTitleController.clear();
          _fetchJobTitles(); // Refresh list
          Navigator.pop(context); // Close the dialog
        } else {
          _showSnackBar('Failed to add job title: ${responseBody['message']}');
        }
      } else {
        _showSnackBar('Failed to add job title');
      }
    } catch (e) {
      _showSnackBar('Error occurred while adding job title');
    }
  }

  Future<void> _deleteJobTitle(String jobtitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$jobtitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/deletejobtitle.php');
      final response = await http.post(
        url,
        body: jsonEncode({'name': jobtitle}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          _showSnackBar('Job Title deleted successfully');
          _fetchJobTitles();
        } else {
          _showSnackBar(
              'Failed to delete job title: ${responseBody['message']}');
        }
      } else {
        _showSnackBar('Failed to delete job title. Please try again later.');
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error occurred while deleting job title');
    }
  }

  void _showAddJobTitleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Add New Job Title',
                        style: const TextStyle(
                          fontFamily: 'NexaBold', // Replace with your font
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a job title'
                          : null,
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      hint: const Text(
                        'Select Department',
                        style: TextStyle(fontSize: 16),
                      ),
                      items: _departments
                          .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ))
                          .toList(),
                      value: _selectedDepartment,
                      onChanged: (value) {
                        setModalState(() {
                          _selectedDepartment = value;
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      validator: (value) =>
                      value == null ? 'Please select department' : null,
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.only(right: 8),
                      ),
                      iconStyleData: const IconStyleData(
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black45,
                        ),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addJobTitle();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffeef444c),
                          foregroundColor: Colors.white,
                          elevation: 7,
                          shadowColor: const Color(0xffeef444c),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Add Job Title',
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily:
                              'NexaRegular', // Replace with your font
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  final Color primaryColor = const Color(0xffeef444c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Job Title Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const departmentmanagement()),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _jobTitles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/registration.json",
                    height: 200,
                  ),
                  Text(
                    'No job titles available',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _jobTitles.length,
              itemBuilder: (context, index) {
                final jobTitle = _jobTitles[index];
                return Card(
                  margin:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      jobTitle['jobtitle']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Department: ${jobTitle['department']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteJobTitle(jobTitle['jobtitle']!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddJobTitleDialog,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    super.dispose();
  }
}