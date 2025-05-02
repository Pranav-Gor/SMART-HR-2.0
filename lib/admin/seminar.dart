import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/projectmanagement.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/loginpage.dart';

class seminarscreen extends StatefulWidget {
  const seminarscreen({super.key});

  @override
  State<seminarscreen> createState() => _seminarscreenState();
}

class _seminarscreenState extends State<seminarscreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  DateTime? _selectedDate;
  Color primary = const Color(0xffeef444c);
  List<Map<String, dynamic>> _seminars = [];
  bool _isAddingSeminar = false;

  // Validation errors
  String? _titleError;
  String? _placeError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Validation methods
  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length < 5) {
      return 'Minimum 5 characters';
    }
    return null;
  }

  String? _validatePlace(String? value) {
    if (value == null || value.isEmpty) {
      return 'Place is required';
    }
    if (value.length < 3) {
      return 'Minimum 3 characters';
    }
    return null;
  }

  String? _validateDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    if (value.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _titleError = _validateTitle(_titleController.text);
      _placeError = _validatePlace(_placeController.text);
      _dateError = _validateDate(_selectedDate);
    });

    return _titleError == null && _placeError == null && _dateError == null;
  }

  Future<void> _addSeminarToFirebase() async {
    if (!_validateForm()) return;

    setState(() => _isAddingSeminar = true);

    String formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}";
    String seminarTitle = _titleController.text;
    String seminarPlace = _placeController.text;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending email notification...')),
      );
    }

    // First, send email notification
    bool emailSent = await _sendSeminarNotification(
        seminarTitle, seminarPlace, formattedDate);

    if (emailSent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sent successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send email notification!')),
        );
      }
      setState(() => _isAddingSeminar = false);
      return; // Stop if email fails
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adding seminar...')),
      );
    }

    // Proceed with adding the seminar
    var url = Uri.parse('http://192.168.29.211/hr_api/addseminar.php');

    try {
      var response = await http.post(
        url,
        body: {
          'title': seminarTitle,
          'place': seminarPlace,
          'date': formattedDate,
        },
      );

      if (response.statusCode == 200) {
        _titleController.clear();
        _placeController.clear();
        _fetchData();

        if (mounted) {
          setState(() {
            _selectedDate = null;
            _isAddingSeminar = false;
            _titleError = null;
            _placeError = null;
            _dateError = null;
          });

          Navigator.pop(context); // Close modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seminar added successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add seminar!')),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error, please try again!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingSeminar = false);
      }
    }
  }

  /// Sends email notification before adding a seminar
  Future<bool> _sendSeminarNotification(
      String title, String place, String date) async {
    var notificationUrl = Uri.parse(
        'http://192.168.29.211/hr_api/send_seminar_notification.php');

    try {
      var notificationResponse = await http.post(
        notificationUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'place': place,
          'date': date,
        }),
      );

      if (notificationResponse.statusCode == 200) {
        final responseData = json.decode(notificationResponse.body);
        return responseData['success'] == true;
      }
    } catch (emailError) {
      print('Error sending email: $emailError');
    }

    return false; // Email sending failed
  }

  Future<void> _selectDate(BuildContext context,
      {VoidCallback? onDateSelected}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primary,
            colorScheme: ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
      if (onDateSelected != null) {
        onDateSelected();
      }
    }
  }

  // Rest of your existing methods (deleteSeminar, fetchData, etc.) remain the same...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seminar Settings',
          style: TextStyle(
            fontFamily: 'NexaRegular',
            color: Colors.white,
          ),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xffeef444c),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child: Icon(
                        Icons.person,
                        color: Colors.black26,
                        size: 55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hello, Admin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NexaBold',
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.redeem),
              title: const Text(
                'Reward Settings',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const adminreward()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text(
                'Registration',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const registrationpage()));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.event_note,
                color: primary,
              ),
              title: Text(
                'Seminar',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                  color: primary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => seminarscreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text(
                'Project Management',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => projectmanagement()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text(
                'View All Employees',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => showemployee()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text(
                'Payroll',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => payrollscreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text(
                'Leave Requests',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => showleave()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text(
                'Company Time',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => companytimescreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text(
                'Department Manage',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => departmentmanagement()));
              },
            ),
            const Divider(
              color: Color(0xffeef444c),
              indent: Checkbox.width,
              endIndent: Checkbox.width,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 17,
                ),
              ),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('token');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 35),
            ),
            const Divider(),
            const ListTile(
              title: Text(
                'Copyright © 2024 TechnoGuide Infosoft',
                style: TextStyle(
                  fontFamily: 'NexaRegular',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSeminarModal,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildSeminarList(),
    );
  }

  Widget _buildSeminarList() {
    // Reverse the list to show latest first
    final reversedSeminars = _seminars.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reversedSeminars.length,
      itemBuilder: (context, index) {
        final seminar = reversedSeminars[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              seminar['title'].toString().toUpperCase(),
              style: const TextStyle(
                fontFamily: 'NexaBold',
                fontSize: 18,
                color: Colors.redAccent,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  seminar['place'],
                  style: const TextStyle(
                    fontFamily: 'NexaBold',
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Date: ${seminar['date']}',
                  style: const TextStyle(
                    fontFamily: 'NexaBold',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _deleteSeminar(seminar['seminarID'].toString(), seminar),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSeminarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Add New Seminar',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: "NexaBold",
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 400,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 10,
                                child: Icon(
                                  Icons.title_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  keyboardType: TextInputType.text,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      border: InputBorder.none,
                                      hintText: "Seminar Title",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[600])),
                                  onChanged: (value) {
                                    setModalState(() {
                                      _titleError = _validateTitle(value);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_titleError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            _titleError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 400,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 10,
                                child: Icon(
                                  Icons.place_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: TextField(
                                  controller: _placeController,
                                  keyboardType: TextInputType.text,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      border: InputBorder.none,
                                      hintText: "Place",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[600])),
                                  onChanged: (value) {
                                    setModalState(() {
                                      _placeError = _validatePlace(value);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_placeError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            _placeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () => _selectDate(
                                context,
                                onDateSelected: () => setModalState(() {}),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13, horizontal: 15),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 8),
                                  Text(
                                    'Choose Date',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'NexaRegular'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    _selectedDate == null
                                        ? 'No date selected'
                                        : 'Selected: ${_selectedDate!.toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'NexaRegular',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_dateError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            _dateError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isAddingSeminar ? null : _addSeminarToFirebase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isAddingSeminar
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NexaBold',
                              ),
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

// Your existing fetchData and deleteSeminar methods...
  Future<void> _fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showseminar.php'));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List) {
          setState(() {
            _seminars = List<Map<String, dynamic>>.from(decodedResponse);
          });
        } else if (decodedResponse is Map &&
            decodedResponse.containsKey('success') &&
            !decodedResponse['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Server error: ${decodedResponse['message']}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load data: HTTP ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteSeminar(
      String seminarID, Map<String, dynamic> seminar) async {
    try {
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Cancel'),
            content:
                const Text('Are you sure you want to Cancel this seminar?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: TextStyle(color: primary)),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child:
                    const Text('Confirm', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmDelete != true) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleting seminar...')),
        );
      }

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/deleteseminar.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'seminarID': seminarID}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final seminarData = {
            'title': seminar['title'],
            'place': seminar['place'],
            'date': seminar['date'],
          };

          final notifyUrl =
              Uri.parse('http://192.168.29.211/hr_api/send_cancelseminar.php');
          final notifyResponse = await http.post(
            notifyUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(seminarData),
          );

          if (notifyResponse.statusCode == 200) {
            final notifyData = json.decode(notifyResponse.body);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    notifyData['message'] ??
                        'Seminar deleted and cancellation emails sent',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          }
          await _fetchData();
        }
      }
    } catch (e) {
      print('Error deleting seminar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
