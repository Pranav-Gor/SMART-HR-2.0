// ignore_for_file: unnecessary_type_check, unused_field, unused_element, body_might_complete_normally_nullable

import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/companytimescreen.dart';
import 'package:smart_hr/admin/department.dart';
import 'package:smart_hr/admin/empregisterpage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/admin/payrollscreen.dart';
import 'package:smart_hr/admin/rewardscreen.dart';
import 'package:smart_hr/admin/seminar.dart';
import 'package:smart_hr/admin/showemp.dart';
import 'package:smart_hr/admin/showleave.dart';
import 'package:smart_hr/admin/subtask.dart';
import 'package:smart_hr/loginpage.dart';

class projectmanagement extends StatefulWidget {
  const projectmanagement({super.key});

  @override
  State<projectmanagement> createState() => _projectmanagementState();
}

class _projectmanagementState extends State<projectmanagement> {
  // Controllers for Project Tab
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _technologiesController = TextEditingController();
  final TextEditingController _employeeTextFieldController =
      TextEditingController();

  // Controllers for Allowance Tab
  final TextEditingController _petrolPriceController = TextEditingController();
  final TextEditingController _dieselPriceController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  // Data Holders for Project Tab Dropdowns
  List<Map<String, String>> allJobTitles = [];
  List<Map<String, String>> allemployee = [];
  List<String> filteredJobTitles = [];
  List<String> filteredemployee = [];
  String? selectedDepartment;
  String? selectedJobTitle;
  String? selectedemployee; // Team Leader selection
  List<String> departments = []; // Declare a variable to hold department data
  List<String> jobtitles = [];

  // Color Theme
  final Color primary = const Color(0xffeef444c);

  // Team Leader Selection
  late Future<List<String>>
      _fetchemployeeFuture; // Not used, maybe remove later?
  String? _selectedEmployee; // Represents the selected team leader

  // Team Member Selection
  List<String> _selectedEmployees = []; // Represents selected team members

  // Date Selection
  DateTime? _selectedDate; // Start Date
  DateTime? selectedDate; // End Date

  // -- Initialization and Disposal --
  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
    fetchDepartments();
    fetchJobTitles();
    // Potentially load existing allowance prices here if needed
  }

  @override
  void dispose() {
    // Dispose Project Controllers
    _projectTitleController.dispose();
    _descriptionController.dispose();
    _technologiesController.dispose();
    _employeeTextFieldController.dispose();

    // Dispose Allowance Controllers
    _petrolPriceController.dispose();
    _dieselPriceController.dispose();

    super.dispose();
  }

  // -- Date Picker Functions --
  Future<void> _selectDate(BuildContext context) async {
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
        _selectedDate = picked; // Start Date
      });
    }
  }

  Future<void> selectDate(BuildContext context) async {
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // End Date
      });
    }
  }

  // --- API Functions ---

  // Add Project
  void _addproject() async {
    print("Project Title: ${_projectTitleController.text}");
    print("Team Leader: $_selectedEmployee");
    print("Team Members: ${_employeeTextFieldController.text}");
    print("Project Description: ${_descriptionController.text}");
    print("Technologies: ${_technologiesController.text}");
    print("Start Date: $_selectedDate");
    print("End Date: $selectedDate");

    // Basic Validation
    if (_projectTitleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _technologiesController.text.isEmpty ||
        _employeeTextFieldController.text.isEmpty ||
        _selectedEmployee == null ||
        selectedDate == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all project fields!')),
      );
      return; // Stop execution if validation fails
    }

    try {
      var url = Uri.parse(
          'http://192.168.29.211/hr_api/addproject.php'); // Use your actual IP

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'projecttitle': _projectTitleController.text,
          'teamleader': _selectedEmployee.toString(), // Send the leader's name/ID
          'teammemners': _selectedEmployees.join(','), // Changed from 'teammembers' to 'teammemners' to match PHP
          'projectdescription': _descriptionController.text,
          'technologies': _technologiesController.text,
          'startdate': _selectedDate!.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
          'enddate': selectedDate!.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        }),
      );

      print('Add Project Response status: ${response.statusCode}');
      print('Add Project Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Successful insertion
          _projectTitleController.clear();
          _employeeTextFieldController.clear();
          _descriptionController.clear();
          _technologiesController.clear();
          setState(() {
            selectedDepartment = null;
            selectedJobTitle = null;
            _selectedEmployee = null;
            _selectedEmployees = [];
            _selectedDate = null;
            selectedDate = null;
            filteredJobTitles = [];
            filteredemployee = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project added successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to add project: ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add project! Server error.')),
        );
      }
    } catch (e) {
      print("Error adding project: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
  // Submit Allowance Prices
  void _submitAllowance() async {
    final String petrolPriceStr = _petrolPriceController.text.trim();
    final String dieselPriceStr = _dieselPriceController.text.trim();

    // Validation
    if (petrolPriceStr.isEmpty || dieselPriceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both petrol and diesel prices.')),
      );
      return;
    }

    final double? petrolPrice = double.tryParse(petrolPriceStr);
    final double? dieselPrice = double.tryParse(dieselPriceStr);

    if (petrolPrice == null || dieselPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric prices.')),
      );
      return;
    }

    if (petrolPrice <= 0 || dieselPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices must be greater than zero.')),
      );
      return;
    }

    print("Petrol Price/km: $petrolPrice");
    print("Diesel Price/km: $dieselPrice");

    // Replace with your actual allowance setting API endpoint
    var url = Uri.parse('http://192.168.29.211/hr_api/set_allowance.php');

    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          // Ensure keys match exactly what your PHP script expects
          'petrol_price_km': petrolPrice,
          'diesel_price_km': dieselPrice,
        }),
      );

      print('Allowance Submit Response status: ${response.statusCode}');
      print('Allowance Submit Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Allowance prices updated successfully!')),
          );
          // Optionally clear fields or fetch updated prices if needed
          // _petrolPriceController.clear();
          // _dieselPriceController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to update prices: ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        // Handle server error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to update allowance prices! Server error.')),
        );
      }
    } catch (e) {
      print("Error submitting allowance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // --- Data Fetching Functions ---

  // Fetch Departments
  Future<void> fetchDepartments() async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/showdept.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          setState(() {
            departments = jsonResponse
                .map((dept) => dept['deptName'].toString())
                .toList();
          });
          print("Fetched Departments: $departments");
        } else {
          print('Error: Expected a JSON array for departments');
          _showErrorSnackBar('Unexpected response format for departments');
        }
      } else {
        print(
            'Error: Failed to fetch departments. Status code: ${response.statusCode}');
        _showErrorSnackBar('Failed to fetch departments');
      }
    } catch (e) {
      print('Error fetching departments: $e');
      _showErrorSnackBar('Error occurred while fetching departments');
    }
  }

  // Fetch Job Titles
  Future<void> fetchJobTitles() async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/showjobtitle.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          setState(() {
            allJobTitles = jsonResponse
                .map((job) => {
                      // Ensure keys match EXACTLY what API returns
                      'jobtitle': job['title']?.toString() ?? 'N/A',
                      'department': job['deptName']?.toString() ?? 'N/A'
                    })
                .toList();
            print("Fetched All Job Titles: $allJobTitles");
          });
        } else {
          print('Error: Expected a JSON array for job titles');
          _showErrorSnackBar('Unexpected response format for job titles');
        }
      } else {
        print(
            'Error: Failed to fetch job titles. Status code: ${response.statusCode}');
        _showErrorSnackBar('Failed to fetch job titles');
      }
    } catch (e) {
      print('Error fetching job titles: $e');
      _showErrorSnackBar('Error occurred while fetching job titles');
    }
  }

  // Fetch Employee Data (for dropdowns)
  Future<void> _fetchEmployeeData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp_job.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Raw Employee Data: $data'); // Debug print

        setState(() {
          allemployee = data
              .map((emp) => {
                    // Use null-aware operators and provide defaults
                    'titles': emp['titles']?.toString() ??
                        '', // Key should match API exactly
                    'firstName': emp['firstName']?.toString() ?? 'No Name',
                    'userID': emp['userID']?.toString() ??
                        '' // Assuming userID might be useful later
                  })
              .toList();
          print('Processed Employee Data: $allemployee'); // Debug print
        });
      } else {
        throw Exception('Failed to fetch employees: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching employees: $error');
      _showErrorSnackBar('Failed to fetch employee data');
      setState(() {
        allemployee = []; // Set to empty list on error
      });
    }
  }

  // --- Filtering Functions ---

  // Filter Job Titles based on Selected Department
  void filterJobTitles() {
    if (selectedDepartment == null) {
      setState(() {
        filteredJobTitles = [];
        selectedJobTitle = null; // Reset job title selection
        filterTeamLeader(); // Reset team leader selection as well
      });
      return;
    }

    print('Filtering job titles for department: $selectedDepartment');
    print('All job titles available: $allJobTitles');

    setState(() {
      filteredJobTitles = allJobTitles
          .where((job) => job['department'] == selectedDepartment)
          .map((job) => job['jobtitle']!)
          .toList();
      selectedJobTitle =
          null; // Reset job title selection when department changes
      print("Filtered Job Titles: $filteredJobTitles");
      filterTeamLeader(); // Reset team leader as job title list changed
    });
  }

  // Filter Team Leaders based on Selected Job Title
  void filterTeamLeader() {
    if (selectedJobTitle == null || selectedJobTitle!.isEmpty) {
      print('Selected Job Title is null or empty, clearing team leaders.');
      setState(() {
        filteredemployee = [];
        _selectedEmployee = null; // Reset team leader selection
      });
      return;
    }

    print('Filtering team leaders for job title: "$selectedJobTitle"');
    print('All employee data: $allemployee');

    final String searchTitleLower = selectedJobTitle!.trim().toLowerCase();

    setState(() {
      filteredemployee = allemployee
          .where((emp) {
            // Safely access 'titles', default to empty string if null
            String empTitles =
                (emp['titles'] ?? '').toString().trim().toLowerCase();

            // Check if the employee's titles string contains the search title
            bool matches = empTitles.contains(searchTitleLower);
            print(
                'Comparing: Employee Titles "$empTitles" vs Search Title "$searchTitleLower" -> Match: $matches');
            return matches;
          })
          .map((emp) {
            // Safely access 'firstName', default if null
            return emp['firstName']?.toString() ?? 'Unnamed';
          })
          .where(
              (name) => name != 'Unnamed') // Filter out default names if needed
          .toList();

      _selectedEmployee = null; // Reset selection when list changes
      print('Filtered Team Leaders: $filteredemployee');
    });
  }

  // --- Helper Functions ---

  // Show Error SnackBar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to Employee Selection Screen
  void _openEmployeeSelectionScreen() {
    if (selectedJobTitle == null || selectedJobTitle!.isEmpty) {
      _showErrorSnackBar(
          "Please select a Job Title first to assign team members.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeSelectionScreen(
          selectedJobTitle: selectedJobTitle!,
          // Pass the *current* list of selected employees
          initiallySelectedEmployees: List<String>.from(_selectedEmployees),
          onSelect: (returnedSelectedEmployees) {
            // Callback when the selection screen is popped
            setState(() {
              print(
                  "Employee Selection Screen returned: $returnedSelectedEmployees");
              _selectedEmployees = returnedSelectedEmployees;
              _updateSelectedEmployeesText();
            });
          },
        ),
      ),
    );
  }

  // Update TextField with selected employees
  void _updateSelectedEmployeesText() {
    _employeeTextFieldController.text =
        _selectedEmployees.join(', '); // Use comma for clarity
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    // Use DefaultTabController to manage tabs
    return DefaultTabController(
      length: 3, // Increased to 3 tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Project Management', // Updated title
            style: TextStyle(
              fontFamily: 'NexaRegular',
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          iconTheme: const IconThemeData(
            color: Colors.white, // Ensure icons are white
          ),
        ),
        // --- Drawer ---
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: primary),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child:
                          Icon(Icons.person, color: Colors.black26, size: 55),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Hello, Admin!',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'NexaBold',
                          fontSize: 24),
                    ),
                  ],
                ),
              ),
              // Navigation Items (with styling consistency)
              _buildDrawerItem(Icons.home, 'Home', () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              }),
              _buildDrawerItem(Icons.redeem, 'Reward Settings', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const adminreward()));
              }),
              _buildDrawerItem(Icons.person_add, 'Registration', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const registrationpage()));
              }),
              _buildDrawerItem(Icons.event_note, 'Seminar', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const seminarscreen()));
              }),
              // Current screen highlighted
              ListTile(
                leading: Icon(Icons.task, color: primary),
                title: Text(
                  'Project Management',
                  style: TextStyle(
                      fontFamily: 'NexaRegular',
                      fontSize: 17,
                      color: primary // Highlight color
                      ),
                ),
                onTap: () =>
                    Navigator.pop(context), // Just close drawer if already here
              ),
              _buildDrawerItem(Icons.people, 'View All Employees', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const showemployee()));
              }),
              _buildDrawerItem(Icons.currency_rupee, 'Payroll', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const payrollscreen()));
              }),
              _buildDrawerItem(Icons.calendar_today, 'Leave Requests', () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const showleave()));
              }),
              _buildDrawerItem(Icons.schedule, 'Company Time', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const companytimescreen()));
              }),
              _buildDrawerItem(Icons.home_work, 'Department Manage', () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const departmentmanagement()));
              }),
              const Divider(
                  color: Color(0xffeef444c),
                  indent: Checkbox.width,
                  endIndent: Checkbox.width),
              // Logout
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout',
                    style: TextStyle(fontFamily: 'NexaRegular', fontSize: 17)),
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) =>
                        false, // Remove all routes behind login
                  );
                },
              ),
              Container(margin: const EdgeInsets.only(top: 35)),
              const Divider(),
              const ListTile(
                title: Text(
                  'Copyright © 2024 TechnoGuide Infosoft',
                  style: TextStyle(
                      fontFamily: 'NexaRegular',
                      fontSize: 14,
                      color: Colors.grey),
                ),
              ),
            ],
          ),
        ),

        // --- TabBarView ---
        body: TabBarView(
          children: [
            // --- Tab 1: New Project ---
            _buildNewProjectTab(),

            // --- Tab 2: Current Projects ---
            _buildCurrentProjectsTab(),

            // --- Tab 3: Allowance Settings ---
            _buildAllowanceTab(),
          ],
        ),

        // --- Bottom Navigation Bar (Tabs) ---
        bottomNavigationBar: SizedBox(
          height: 70, // Adjusted height if needed
          child: TabBar(
            tabs: [
              // Tab 1
              _buildTab('assets/images/pricon.jpg', 'New Project'),
              // Tab 2
              _buildTab('assets/images/curprj.png', 'Projects List'),
              // Tab 3
              _buildTabWithIcon(Icons.local_gas_station, 'Allowance'),
            ],
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: const EdgeInsets.all(5.0),
            indicatorColor: Colors.redAccent,
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for Build Method ---

  // Builds a standard Drawer Item
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]), // Consistent icon color
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'NexaRegular', fontSize: 17),
      ),
      onTap: onTap,
    );
  }

  // Builds a Tab with an Image Asset
  Widget _buildTab(String imagePath, String text) {
    return Tab(
      icon: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        children: [
          Image.asset(imagePath, width: 30, height: 25), // Slightly smaller?
          const SizedBox(height: 4), // Space between icon and text
          Text(
            text,
            textAlign: TextAlign.center, // Center text
            style: const TextStyle(
                fontSize: 12, fontFamily: "NexaBold"), // Slightly smaller font
            overflow: TextOverflow.ellipsis, // Handle overflow
          ),
        ],
      ),
    );
  }

  // Builds a Tab with a Material Icon
  Widget _buildTabWithIcon(IconData icon, String text) {
    return Tab(
      icon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25), // Adjust size as needed
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontFamily: "NexaBold"),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Widget Builder for "New Project" Tab ---
  Widget _buildNewProjectTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), // Top padding

          // Project Title
          _buildTextFieldWithTitle(
            'Project Title',
            _projectTitleController,
            Icons.title_rounded,
            "Enter Your Project Title",
            TextInputType.text,
          ),

          // Department Dropdown
          _buildDropdownWithTitle("Department", 'Select Your Department',
              selectedDepartment, departments, (newValue) {
            setState(() {
              selectedDepartment = newValue;
              filterJobTitles(); // Trigger filtering for job titles
            });
          }),

          // Job Title Dropdown
          _buildDropdownWithTitle(
            "Job Title",
            'Select Your Job Title',
            selectedJobTitle,
            filteredJobTitles, // Use filtered list
            (newValue) {
              setState(() {
                selectedJobTitle = newValue;
                filterTeamLeader(); // Trigger filtering for team leader
              });
            },
            // Disable if no department selected
            enabled: selectedDepartment != null && departments.isNotEmpty,
            hintTextWhenDisabled: "Select Department First",
          ),

          // Team Leader Dropdown
          _buildDropdownWithTitle(
            "Assign Team Leader",
            'Select Team Leader',
            _selectedEmployee, // Use _selectedEmployee for value
            filteredemployee, // Use filtered list
            (newValue) {
              setState(() {
                _selectedEmployee = newValue; // Update team leader
                print('Selected Team Leader: $_selectedEmployee');
              });
            },
            // Disable if no job title selected
            enabled: selectedJobTitle != null && filteredJobTitles.isNotEmpty,
            hintTextWhenDisabled: "Select Job Title First",
          ),

          // Add Team Members
          _buildTextFieldWithTitle(
            'Assign Team Members',
            _employeeTextFieldController, // Controller for display
            Icons.person_add,
            "Click to Select Employees",
            TextInputType.none, // Not directly editable
            readOnly: true,
            onTap: _openEmployeeSelectionScreen, // Open selection screen on tap
            enabled: selectedJobTitle !=
                null, // Enable only if job title is selected
          ),

          // Project Description
          _buildTextFieldWithTitle(
            'Project Description',
            _descriptionController,
            Icons.description_outlined,
            "Enter Your Project Description",
            TextInputType.multiline, // Allow multiple lines
            maxLines: 3, // Example max lines
          ),

          // Technologies Demanded
          _buildTextFieldWithTitle(
            'Technologies Demanded',
            _technologiesController,
            Icons.laptop,
            "Enter required technologies (e.g., Flutter, PHP, MySQL)",
            TextInputType.text,
          ),

          const SizedBox(height: 20),
          const Text(
            'Project Duration :',
            style: TextStyle(fontSize: 20, fontFamily: "NexaBold"),
          ),
          const SizedBox(height: 15),

          // Start Date Picker
          _buildDatePicker(
            'Start Date:',
            _selectedDate,
            () => _selectDate(context), // Use the specific start date picker
          ),

          // End Date Picker
          _buildDatePicker(
            'End Date:',
            selectedDate, // Use the specific end date variable
            () => selectDate(context), // Use the specific end date picker
          ),

          const SizedBox(height: 30),

          // Submit Button
          Center(
            child: SizedBox(
              width: screenWidth * 0.9, // Responsive width
              height: 48,
              child: ElevatedButton(
                onPressed: _addproject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 7,
                  shadowColor: Colors.red.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.add_task),
                    //SizedBox(width: 8),
                    Text(
                      'Add Project',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'NexaRegular',
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  // --- Widget Builder for "Current Projects" Tab ---
  Widget _buildCurrentProjectsTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Optional: Image or Header
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 10),
            height: 180, // Adjusted size
            width: screenWidth * 0.9, // Responsive width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/curnproj.png', // Your image asset
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Title for the list
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              'Active Projects List',
              style: TextStyle(fontSize: 19, fontFamily: "NexaBold"),
            ),
          ),

          // Project List Container
          Container(
            // Use constraints for height instead of fixed height
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.55, // Max height relative to screen
            ),
            width: screenWidth * 0.95, // Responsive width
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                // Optional background or border
                // color: Colors.grey[100],
                // borderRadius: BorderRadius.circular(8),
                ),
            child: FutureBuilder<List<Project>>(
              future: fetchProjectsFromMySQL(),
              builder: (context, AsyncSnapshot<List<Project>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.redAccent));
                } else if (snapshot.hasError) {
                  print("Error fetching projects: ${snapshot.error}");
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading projects: ${snapshot.error}',
                        style: TextStyle(color: Colors.red)),
                  ));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active projects found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ));
                } else {
                  // Display the list
                  return ListView.builder(
                    shrinkWrap: true, // Important within constrained height
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var project = snapshot.data![index];
                      return Card(
                        // Use Cards for better separation
                        margin: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          // Make the whole card tappable
                          borderRadius:
                              BorderRadius.circular(12), // Match card shape
                          onTap: () {
                            print(
                                "Tapped on Project ID: ${project.projectid}, Title: ${project.projecttitle}");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => subtask(
                                  projecid: project
                                      .projectid, // Ensure it's passed correctly
                                  projectName: project.projecttitle,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.projecttitle,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.description_outlined,
                                        color: Colors.grey[600], size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      // Allow description to wrap/ellipsis
                                      child: Text(
                                        project.projectdescription.isNotEmpty
                                            ? project.projectdescription
                                            : 'No description available',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                // You could add more info here like team lead, dates etc. if available
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builder for "Allowance" Tab ---
  Widget _buildAllowanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Fuel Allowance Rates',
            style: TextStyle(
                fontSize: 22, fontFamily: "NexaBold", color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter the price per kilometer (KM) for fuel reimbursement.',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          const SizedBox(height: 30),

          // Petrol Price Input
          _buildAllowanceInputField(
            'Petrol Price / KM',
            _petrolPriceController,
            Icons.local_gas_station, // Generic fuel icon
            "e.g., 10.50", // Hint for format
          ),

          // Diesel Price Input
          _buildAllowanceInputField(
            'Diesel Price / KM',
            _dieselPriceController,
            Icons.local_gas_station, // Can use the same icon or a different one
            "e.g., 9.75",
          ),

          const SizedBox(height: 40),

          // Submit Button for Allowance
          Center(
            child: SizedBox(
              width: screenWidth * 0.9,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    _submitAllowance, // Link to the allowance submission function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, // Different color?
                  foregroundColor: Colors.white,
                  elevation: 7,
                  shadowColor: Colors.deepOrange.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Icon(Icons.save),
                    //SizedBox(width: 8),
                    Text(
                      'Save Allowance Rates',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'NexaRegular',
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  // --- Reusable Helper Widgets for Input Fields ---

  // Helper for standard text fields with titles
  Widget _buildTextFieldWithTitle(
      String title,
      TextEditingController controller,
      IconData icon,
      String hintText,
      TextInputType keyboardType,
      {bool readOnly = false,
      VoidCallback? onTap,
      int? maxLines = 1, // Default to single line
      bool enabled = true} // Optional enabled flag
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontFamily: "NexaBold"),
          ),
          const SizedBox(height: 8),
          AbsorbPointer(
            absorbing: !enabled, // Disable interaction if not enabled
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5, // Make it look disabled
              child: GestureDetector(
                // Use GestureDetector for onTap functionality
                onTap: enabled ? onTap : null, // Only trigger tap if enabled
                child: Container(
                  height:
                      maxLines == 1 ? 50 : null, // Auto height for multiline
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.red, size: 20),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          readOnly: readOnly,
                          onTap:
                              onTap, // TextField's onTap still works if readOnly is false
                          maxLines: maxLines,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: hintText,
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10), // Adjust padding
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Dropdown buttons with titles
  Widget _buildDropdownWithTitle(
      String title,
      String hint,
      String? selectedValue,
      List<String> items,
      ValueChanged<String?> onChanged,
      {bool enabled = true,
      String hintTextWhenDisabled = "N/A"} // Enable/disable dropdown
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontFamily: "NexaBold"),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5, // Visual cue for disabled state
              child: DropdownButton2<String>(
                isExpanded: true,
                hint: Text(
                  enabled
                      ? hint
                      : hintTextWhenDisabled, // Show appropriate hint
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black54 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                items: enabled // Only show items if enabled
                    ? items
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList()
                    : [], // Empty list if disabled
                value: enabled ? selectedValue : null, // Value only if enabled
                onChanged:
                    enabled ? onChanged : null, // Allow changes only if enabled
                buttonStyleData: ButtonStyleData(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(Icons.arrow_drop_down,
                      color: enabled ? Colors.black : Colors.grey),
                  iconSize: 25,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  offset: const Offset(0, -5),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Date Picker rows
  Widget _buildDatePicker(
      String label, DateTime? selectedDateValue, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 17,
                fontFamily: "Nexaregular",
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 8),
                    Text('Choose Date',
                        style:
                            TextStyle(fontSize: 14, fontFamily: 'NexaRegular')),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  // Optional: add border for clarity
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[400]!)),
                  ),
                  child: Text(
                    selectedDateValue == null
                        ? 'No date chosen'
                        : 'Selected: ${selectedDateValue.toLocal().toString().split(' ')[0]}', // Format YYYY-MM-DD
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'NexaRegular',
                      color: selectedDateValue == null
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Allowance Input Fields
  Widget _buildAllowanceInputField(String title,
      TextEditingController controller, IconData icon, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontFamily: "NexaBold"),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: Colors.deepOrange,
                    size: 20), // Different color for allowance?
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true), // Allow decimals
                    // Ensure only numbers and a single decimal point can be entered
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(
                          r'^\d+\.?\d{0,2}')), // Allow numbers and up to 2 decimal places
                    ],
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Text(
                  " ₹ / km", // Indicate currency and unit
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
} // End of _projectmanagementState

// --- Data Model for Project ---
class Project {
  final String projecttitle;
  final String projectdescription;
  final String projectid;

  Project({
    required this.projecttitle,
    required this.projectdescription,
    required this.projectid,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Robust parsing with null checks and defaults
    return Project(
      projecttitle: json['projectTitle']?.toString() ?? 'Untitled Project',
      projectdescription: json['projectDescription']?.toString() ?? '',
      projectid:
          json['projectID']?.toString() ?? '', // Ensure project ID is handled
    );
  }
}

// --- API Function to Fetch Projects (Moved outside State class) ---
Future<List<Project>> fetchProjectsFromMySQL() async {
  try {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/showproject.php'));

    if (response.statusCode == 200) {
      final dynamic decodedResponse = json.decode(response.body);

      // Handle potential variations in API response (list or object with a 'data' key)
      List<dynamic> dataList = [];
      if (decodedResponse is List) {
        dataList = decodedResponse;
      } else if (decodedResponse is Map<String, dynamic> &&
          decodedResponse.containsKey('data')) {
        if (decodedResponse['data'] is List) {
          dataList = decodedResponse['data'];
        }
      } else {
        // If the format is unexpected, assume empty list or handle as error
        print("Unexpected API response format for projects.");
        return []; // Return empty list for formats we don't handle
      }

      if (dataList.isEmpty) {
        print("No projects returned from API.");
        return []; // Return empty list if data is empty
      }

      // Map the JSON data to a list of Project objects safely
      List<Project> projects = dataList
          .map((jsonItem) {
            // Ensure jsonItem is a Map before passing to fromJson
            if (jsonItem is Map<String, dynamic>) {
              return Project.fromJson(jsonItem);
            } else {
              // Log or handle items that are not maps
              print("Skipping invalid item in project list: $jsonItem");
              return null; // Map invalid items to null
            }
          })
          .whereType<
              Project>() // Filter out any nulls resulting from invalid items
          .toList();

      print("Successfully fetched and parsed ${projects.length} projects.");
      return projects;
    } else {
      throw Exception(
          'Failed to load projects. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print("Error in fetchProjectsFromMySQL: $e");
    // Re-throw the exception or return an empty list, depending on desired error handling
    throw Exception('Failed to load projects: $e');
  }
}

// --- Employee Selection Screen Widget ---
class EmployeeSelectionScreen extends StatefulWidget {
  final List<String>
      initiallySelectedEmployees; // Pass the already selected ones
  final Function(List<String>) onSelect;
  final String selectedJobTitle; // Filter based on this

  const EmployeeSelectionScreen({
    super.key,
    required this.initiallySelectedEmployees,
    required this.selectedJobTitle,
    required this.onSelect,
  });

  @override
  _EmployeeSelectionScreenState createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  List<Map<String, dynamic>> _allEmployees = [];
  List<String> _filteredEmployeeNames = [];
  List<String> _tempSelectedEmployees = []; // Manage selection locally
  bool _isLoading = true;
  String _errorMessage = ''; // To show errors on screen

  @override
  void initState() {
    super.initState();
    // Initialize local selection with the list passed from the previous screen
    _tempSelectedEmployees =
        List<String>.from(widget.initiallySelectedEmployees);
    _fetchAndFilterEmployees();
  }

  Future<void> _fetchAndFilterEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp_job.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allEmployees = List<Map<String, dynamic>>.from(data);

        print('Raw employee data fetched: ${_allEmployees.length} records');

        final String searchTitleLower =
            widget.selectedJobTitle.trim().toLowerCase();

        // Filter based on job title (case-insensitive and contains)
        _filteredEmployeeNames = _allEmployees
            .where((emp) {
              String empTitles =
                  (emp['titles'] ?? '').toString().trim().toLowerCase();
              return empTitles.contains(searchTitleLower);
            })
            .map((emp) => emp['firstName']?.toString() ?? '') // Get names
            .where((name) => name.isNotEmpty) // Remove empty names
            .toSet() // Remove duplicates if any employee has multiple matching titles
            .toList(); // Convert back to list

        print('Filtering for job title: "$searchTitleLower"');
        print('Filtered Employee Names: $_filteredEmployeeNames');

        if (_filteredEmployeeNames.isEmpty) {
          _errorMessage =
              'No employees found matching the job title "${widget.selectedJobTitle}".';
        }

        setState(() => _isLoading = false);
      } else {
        throw Exception('Failed to fetch employees: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching/filtering employees: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading employees. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Team Members'),
        backgroundColor: const Color(0xffeef444c), // Match theme
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontFamily: 'NexaRegular'),
        actions: [
          // Done Button - passes back the locally selected list
          IconButton(
            icon: const Icon(Icons.done, color: Colors.white),
            tooltip: 'Confirm Selection',
            onPressed: () {
              widget.onSelect(
                  _tempSelectedEmployees); // Pass back the current selection
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(_errorMessage,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                )
              : _filteredEmployeeNames.isEmpty
                  ? Center(
                      // This case should be covered by _errorMessage now, but good fallback
                      child: Text(
                        'No employees available for "${widget.selectedJobTitle}".',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredEmployeeNames.length,
                      itemBuilder: (context, index) {
                        final employeeName = _filteredEmployeeNames[index];
                        // Check if this employee is currently selected in the local list
                        final bool isSelected =
                            _tempSelectedEmployees.contains(employeeName);

                        return CheckboxListTile(
                          title: Text(employeeName,
                              style:
                                  const TextStyle(fontFamily: 'NexaRegular')),
                          value: isSelected,
                          activeColor: Colors.redAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                // Add if not already present (though CheckboxListTile handles state visually)
                                if (!isSelected) {
                                  _tempSelectedEmployees.add(employeeName);
                                }
                              } else {
                                // Remove if present
                                _tempSelectedEmployees.remove(employeeName);
                              }
                              print(
                                  "Current temp selection: $_tempSelectedEmployees"); // Debugging
                            });
                          },
                        );
                      },
                    ),
    );
  }
}
