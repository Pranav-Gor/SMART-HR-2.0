import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'department.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({super.key});

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final TextEditingController _departmentController = TextEditingController();
  final Color _primaryColor = const Color(0xffeef444c);
  final _formKey = GlobalKey<FormState>();
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
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
          _showSnackBar('Unexpected response format');
        }
      } else {
        _showSnackBar('Failed to fetch departments');
      }
    } catch (e) {
      _showSnackBar('Error occurred while fetching departments');
    }
  }

  Future<void> _deleteDepartment(String deptName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$deptName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/deletedept.php');
      final response = await http.post(
        url,
        body: {'deptname': deptName},
      );

      if (response.statusCode == 200) {
        _showSnackBar('Department deleted successfully');
        setState(() {
          _departments.remove(deptName);
        });
      } else {
        _showSnackBar('Failed to delete department');
      }
    } catch (e) {
      _showSnackBar('Error occurred while deleting department');
    }
  }

  Future<void> _addDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/adddept.php');
      final response = await http.post(
        url,
        body: jsonEncode({'dept': _departmentController.text.trim()}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showSnackBar('Department added successfully');
        _departmentController.clear();
        _fetchDepartments();
        Navigator.pop(context); // Close the modal
      } else {
        _showSnackBar('Failed to add department');
      }
    } catch (e) {
      _showSnackBar('Error occurred while adding department');
    }
  }

  void _showAddDepartmentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
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
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Add New Department',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _departmentController,
                            decoration: InputDecoration(
                              labelText: 'Department Name',
                              prefixIcon: Icon(Icons.home_work, color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _primaryColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter department name'
                                : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _addDepartment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 7,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Add Department',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'NexaRegular',
                                    fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Department Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 30),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const departmentmanagement()),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _departments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/images/registration.json",
                    height: 200,
                  ),
                  const Text(
                    'No departments available',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final department = _departments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      department,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDepartment(department),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDepartmentModal,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 5,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }
}