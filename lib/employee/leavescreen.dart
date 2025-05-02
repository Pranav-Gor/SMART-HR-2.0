import 'dart:convert';
import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_hr/employee/employeedrawer.dart';

class LeaveLimit {
  final int totalDays;
  int usedDays;
  LeaveLimit(this.totalDays, {this.usedDays = 0});
}

class leavescreen extends StatefulWidget {
  const leavescreen({Key? key, required this.employeeId}) : super(key: key);

  final String employeeId;

  @override
  State<leavescreen> createState() => _leavescreenState();
}

class _leavescreenState extends State<leavescreen> {
  final Color primary = const Color(0xffeef444c);
  String employeeName = "";
  String employeeGender = "";
  String leaveType = 'CL';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _canApplyForLeave = true;

  final Map<String, Map<String, dynamic>> leaveTypeInfo = {
    'CL': {'name': 'Casual Leave', 'forGender': 'all'},
    'SL': {'name': 'Sick Leave', 'forGender': 'all'},
    'PL': {'name': 'Privilege Leave', 'forGender': 'all'},
    'ML': {'name': 'Maternity Leave', 'forGender': 'female'},
  };

  final Map<String, LeaveLimit> leaveLimits = {
    'CL': LeaveLimit(10),
    'SL': LeaveLimit(12),
    'PL': LeaveLimit(15),
    'ML': LeaveLimit(90),
  };

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
    _checkLeaveApplicationEligibility();
  }

  Future<void> _checkLeaveApplicationEligibility() async {
    try {
      final leaveData = await _fetchleaveData();
      final now = DateTime.now();

      leaveLimits.forEach((key, value) => value.usedDays = 0);

      for (var leave in leaveData) {
        if (leave['status'] == 'Approved') {
          final startDate = DateTime.parse(leave['startDate']);
          if (startDate.year == now.year) {
            final endDate = DateTime.parse(leave['endDate']);
            final days = endDate.difference(startDate).inDays + 1;
            final leaveType = leave['leaveType'];
            leaveLimits[leaveType]?.usedDays += days;
          }
        }
      }

      setState(() {});
    } catch (e) {
      print('Error checking leave eligibility: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking leave eligibility: $e')),
      );
    }
  }

  Future<void> fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php'));

      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);

        final employeeData = employeeList.firstWhere(
          (employee) => employee['userID'] == widget.employeeId,
          orElse: () => null,
        );

        if (employeeData != null) {
          setState(() {
            employeeName =
                "${employeeData['firstName']} ${employeeData['lastName']}";
            employeeGender =
                employeeData['gender']?.toString().toLowerCase() ?? "";
          });
        } else {
          setState(() {
            employeeName = "Employee Not Found";
          });
        }
      } else {
        setState(() {
          employeeName = "Error Loading Data";
        });
        throw Exception(
            'Failed to load employee data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      setState(() {
        employeeName = "Error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employee data: $e')),
      );
    }
  }

  Future<void> _selectDate(
      BuildContext context, bool isStartDate, StateSetter setModalState) async {
    DateTime initialDate = isStartDate
        ? (startDate.isBefore(DateTime.now()) ? DateTime.now() : startDate)
        : endDate;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setModalState(() {
        if (isStartDate) {
          startDate =
              DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
          if (startDate.isAfter(endDate)) {
            endDate = startDate;
          }
        } else {
          endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
          if (endDate.isBefore(startDate)) {
            startDate = endDate;
          }
        }
        _checkLeaveApplicationEligibility();
      });
    }
  }

  Future<void> _deleteLeaverequest(String leaveID) async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/deleteleavereq.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'leaveID': leaveID}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Leave request deleted successfully'),
            ),
          );
          setState(() {
            _checkLeaveApplicationEligibility();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ??
                    'Failed to delete leave request')),
          );
        }
      } else {
        throw Exception('Failed to delete leave request');
      }
    } catch (e) {
      print('Error deleting leave request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while deleting: $e')),
      );
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (_reasonController.text.isEmpty || leaveType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }
    final requestedDays = endDate.difference(startDate).inDays + 1;

    if (requestedDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date!')),
      );
      return;
    }
    final leaveLimit = leaveLimits[leaveType];

    if (leaveLimit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid leave type!')),
      );
      return;
    }

    if (leaveLimit.usedDays + requestedDays > leaveLimit.totalDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Exceeds yearly limit of ${leaveLimit.totalDays} days for ${leaveTypeInfo[leaveType]!['name']}!\n'
              'Used: ${leaveLimit.usedDays}, Requesting: $requestedDays'),
        ),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/leaveadd.php'),
        body: {
          'userID': widget.employeeId.toString(),
          'leaveType': leaveType,
          'reason': _reasonController.text,
          'startDate': DateFormat('yyyy-MM-dd').format(startDate),
          'endDate': DateFormat('yyyy-MM-dd').format(endDate),
          'status': "Pending",
        },
      );

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print("Response: ${response.body}");
          _reasonController.clear();
          setState(() {
            startDate = DateTime.now();
            endDate = DateTime.now();
            leaveType = "CL";
            _checkLeaveApplicationEligibility();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Leave application submitted successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseBody['message'] ?? 'Failed to submit.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Server error: Unable to process request.')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchleaveData() async {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/leavedetails.php'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      final List<Map<String, dynamic>> parsedData =
          jsonData.map((item) => item as Map<String, dynamic>).toList();

      final List<Map<String, dynamic>> filteredData = parsedData
          .where((leave) => leave['userID'] == widget.employeeId)
          .toList();

      return filteredData;
    } else {
      throw Exception('Failed to fetch leave data');
    }
  }

  Widget _buildLeaveApplications() {
    return FutureBuilder(
      future: _fetchleaveData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final dynamic data = snapshot.data;
        if (data is! List<Map<String, dynamic>> || data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No leave applications found!',
                  style: TextStyle(fontFamily: 'NexaRegular', fontSize: 15),
                ),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _showAddLeaveModal,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final leaveData = data[index];
            final String fullLeaveTypeName =
                leaveTypeInfo[leaveData['leaveType']]?['name'] ??
                    leaveData['leaveType'];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 7,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type: $fullLeaveTypeName',
                      style: const TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${leaveData['reason']}',
                      style: const TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(leaveData['startDate']))}',
                      style: const TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'End Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(leaveData['endDate']))}',
                      style: const TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(leaveData['status'],
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'NexaRegular')),
                          backgroundColor: _getStatusColor(leaveData['status']),
                        ),
                        if (leaveData['status'] == 'Pending')
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 7,
                                    offset: Offset(3, 3)),
                              ],
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                side: const BorderSide(
                                    color: Colors.red, width: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Nexabold')),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this leave request?'),
                                      actions: <Widget>[
                                        TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            }),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _deleteLeaverequest(
                                                leaveData['leaveID']
                                                    .toString());
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showAddLeaveModal() {
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(
                        child: Text(
                          'Apply for Leave',
                          style: const TextStyle(
                            fontFamily: 'NexaBold',
                            fontSize: 22,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Employee Name: ${employeeName.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'NexaBold',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(8.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8.0),
                        DropdownButtonHideUnderline(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Select Leave Type',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              items: leaveLimits.keys.where((shortCode) {
                                // Filter leave types based on gender
                                if (shortCode == 'ML' &&
                                    employeeGender != 'female') {
                                  return false;
                                }
                                return true;
                              }).map((shortCode) {
                                int remainingDays =
                                    leaveLimits[shortCode]!.totalDays -
                                        leaveLimits[shortCode]!.usedDays;
                                return DropdownMenuItem<String>(
                                  value: shortCode,
                                  enabled: remainingDays > 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(leaveTypeInfo[shortCode]!['name']),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$remainingDays',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              value: leaveType,
                              onChanged: (value) {
                                setModalState(() {
                                  leaveType = value!;
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 50,
                                width: 350,
                                padding:
                                    const EdgeInsets.only(left: 15, right: 14),
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
                                padding: EdgeInsets.only(left: 14, right: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason',
                            labelStyle: TextStyle(
                              fontFamily: 'NexaRegular',
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Leave Dates',
                              style: TextStyle(
                                fontFamily: 'NexaBold',
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: Offset(3, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _selectDate(
                                        context, true, setModalState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13, horizontal: 15),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 8),
                                        Text(
                                          'Start Date',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: 'NexaRegular',
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                Text(
                                  '${startDate.day}-${startDate.month}-${startDate.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'NexaRegular',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: Offset(3, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _selectDate(
                                        context, false, setModalState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13, horizontal: 15),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 8),
                                        Text(
                                          'End Date',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: 'NexaRegular',
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30.0),
                                Text(
                                  '${endDate.day}-${endDate.month}-${endDate.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'NexaRegular',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              _submitLeaveApplication();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 7,
                              shadowColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'NexaRegular',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Leave Application',
          style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: MyDrawer(employeeId: widget.employeeId),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLeaveModal,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildLeaveApplications(),
    );
  }
}
