// ignore_for_file: unused_field, unnecessary_null_comparison, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, avoid_print, use_build_context_synchronously, prefer_const_literals_to_create_immutables, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Employee Class ---
class Employee {
  final String employeeUserID;
  final String firstName;
  final String deptName;

  Employee(
      {required this.employeeUserID,
      required this.firstName,
      required this.deptName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          employeeUserID == other.employeeUserID &&
          firstName == other.firstName &&
          deptName == other.deptName;

  @override
  int get hashCode =>
      employeeUserID.hashCode ^ firstName.hashCode ^ deptName.hashCode;

  @override
  String toString() => firstName; // Used for display
}
// --- End Employee Class ---

// --- Main StatefulWidget ---
class subtask extends StatefulWidget {
  final String projecid;
  final String projectName;

  const subtask({Key? key, required this.projecid, required this.projectName})
      : super(key: key);

  @override
  State<subtask> createState() => _subtaskState();
}
// --- End Main StatefulWidget ---

// --- State Class ---
class _subtaskState extends State<subtask> {
  // --- State Variables ---
  final Color primary = const Color(0xffeef444c); // Main theme color

  DateTime? _selectedDate;
  final TextEditingController _moduleController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();

  final TextEditingController _employeeTextFieldController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<String> _selectedEmployees = []; // Stores selected employee FIRST NAMES
  List<Map<String, dynamic>> tasks = []; // Stores fetched tasks
  bool _isLoadingTasks = true; // Loading state for tasks
  bool _isOnsiteTask = true; // Controls the Address field visibility
  bool _isProcessingCashOut = false; // Debounce flag for Cash Out action
  bool _isDeletingTask = false; // Debounce flag for Delete action

  // --- NEW: Set to keep track of task IDs for which cash out has been processed in this session ---
  // Note: This state is local and will reset if the screen is rebuilt (e.g., navigated away and back).
  // For persistent "paid" status, the backend API (`showtask.php`) should return this information.
  final Set<int> _paidTaskIds = {};

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _fetchTasks(); // Fetch tasks when the widget is initialized
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _moduleController.dispose();
    _taskController.dispose();
    _employeeTextFieldController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Async Methods (API Calls, Date Picker) ---

  // Fetch tasks, employee details, and payout information
  Future<void> _fetchTasks() async {
    // This prevents fetching again if already loading and not empty
    // if (_isLoadingTasks && tasks.isNotEmpty) return; // Keep this commented if you want forced refresh

    if (!mounted) return;
    setState(() {
      _isLoadingTasks = true;
      // Clear paid IDs on refresh to reflect backend state if it were implemented
      // _paidTaskIds.clear(); // Keep this commented unless backend returns paid status
    });

    // Clear tasks for a clean refresh
    if (mounted)
      setState(() {
        tasks = [];
      });

    Map<String, double> payoutMap = {};
    List<Map<String, dynamic>> fetchedTasks = [];
    List<Map<String, dynamic>> fetchedEmployees = [];

    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('http://192.168.29.211/hr_api/showtask.php'))
            .timeout(const Duration(seconds: 20)),
        http
            .get(Uri.parse('http://192.168.29.211/hr_api/showemp_job.php'))
            .timeout(const Duration(seconds: 20)),
      ]);

      if (!mounted) return;

      final taskResponse = responses[0];
      final empResponse = responses[1];

      // Validate Task Response
      if (taskResponse.statusCode == 200 &&
          taskResponse.body.isNotEmpty &&
          taskResponse.body.toLowerCase() != 'null') {
        final dynamic taskJsonData = jsonDecode(taskResponse.body);
        if (taskJsonData is List) {
          fetchedTasks = taskJsonData.cast<Map<String, dynamic>>();
        } else {
          print("Warning: Task data not List: ${taskResponse.body}");
        }
      } else if (taskResponse.statusCode != 200) {
        print('Warning: Task fetch failed: ${taskResponse.statusCode}');
      } else {
        print("Task response empty/null.");
      }

      // Validate Employee Response
      if (empResponse.statusCode == 200 &&
          empResponse.body.isNotEmpty &&
          empResponse.body.toLowerCase() != 'null') {
        final dynamic empJsonData = jsonDecode(empResponse.body);
        if (empJsonData is List) {
          fetchedEmployees = empJsonData.cast<Map<String, dynamic>>();
        } else {
          print("Warning: Emp data not List: ${empResponse.body}");
        }
      } else {
        print(
            "Warning: Emp response error/empty. Status: ${empResponse.statusCode}");
      }

      // Fetch Payout Data
      final relevantTasks = fetchedTasks
          .where((task) => task['projectID']?.toString() == widget.projecid)
          .toList();
      if (relevantTasks.isNotEmpty) {
        try {
          final payoutResponse = await http
              .get(Uri.parse(
                  'http://192.168.29.211/hr_api/payout_distance.php'))
              .timeout(const Duration(seconds: 15));
          if (!mounted) return;
          if (payoutResponse.statusCode == 200 &&
              payoutResponse.body.isNotEmpty &&
              payoutResponse.body.toLowerCase() != 'null') {
            final dynamic payoutJsonData = jsonDecode(payoutResponse.body);
            if (payoutJsonData is List) {
              payoutMap = Map.fromEntries(payoutJsonData
                  .whereType<Map>()
                  .map((entry) {
                String? taskIdStr = entry['taskID']?.toString();
                double? allowance = double.tryParse(
                    entry['calculated_fuel_price']?.toString() ?? '');
                // --- Fetch the paid status if the backend provides it ---
                // Example: bool isPaid = entry['is_paid'] == '1' || entry['is_paid'] == true;
                // If paid, potentially add to _paidTaskIds here if you want initial state from backend
                // if (taskIdStr != null && isPaid) _paidTaskIds.add(int.parse(taskIdStr));
                // --- End Example ---

                if (taskIdStr != null && allowance != null && allowance > 0) {
                  return MapEntry(taskIdStr, allowance);
                }
                return null;
              }).whereType<
                      MapEntry<String, double>>()); // Create map efficiently
            } else {
              print("Warning: Payout data not List: ${payoutResponse.body}");
            }
          } else {
            print(
                'Warning: Payout fetch fail/empty. Status: ${payoutResponse.statusCode}');
          }
        } catch (payoutError) {
          if (!mounted) return;
          print('Error parsing payout: $payoutError');
        }
      }

      // Process and Combine Data
      final Map<String, String> deptMap = {
        for (var emp in fetchedEmployees.whereType<Map>().where(
            (e) => e['usersTableUserID'] != null && e['deptName'] != null))
          emp['usersTableUserID'].toString(): emp['deptName'].toString()
      };
      final Map<String, String> firstNameMap = {
        for (var emp in fetchedEmployees.whereType<Map>().where(
            (e) => e['usersTableUserID'] != null && e['firstName'] != null))
          emp['usersTableUserID'].toString(): emp['firstName'].toString()
      };

      final List<Map<String, dynamic>> finalTasksToShow = relevantTasks
          .map((task) {
            final String? userID = task['userID']?.toString();
            task['deptName'] = deptMap[userID] ?? 'N/A';
            task['firstName'] = firstNameMap[userID] ?? 'Unknown';
            final String? taskIdStr = task['taskID']?.toString();
            final String status = task['status']?.toString() ?? 'unknown';
            task['petrolAllowance'] = (status == 'completed' &&
                    taskIdStr != null &&
                    payoutMap.containsKey(taskIdStr))
                ? payoutMap[taskIdStr]
                : null;

            // --- Add paid status from backend if available ---
            // Example: task['isPaid'] = task['backend_paid_field'] == '1';
            // --- End Example ---

            return task;
          })
          .where((task) => ['completed', 'pending', 'start_in']
              .contains(task['status']?.toString()))
          .toList();

      if (!mounted) return;
      setState(() {
        tasks = finalTasksToShow;
        _isLoadingTasks = false;
      });
    } catch (error) {
      if (!mounted) return;
      print('SEVERE Error _fetchTasks: $error');
      setState(() {
        tasks = [];
        _isLoadingTasks = false;
      });
      if (mounted)
        _showErrorSnackbar('Error loading tasks: ${error.toString()}');
    }
  }

  // Show Date Picker Dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: Colors.black),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primary)),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate && mounted)
      setState(() => _selectedDate = picked);
  }

  // Save Task Logic
  void savetask() async {
    // Input Validation (using helper for conciseness)
    String? validationError = _validateTaskForm();
    if (validationError != null) {
      if (mounted) _showErrorSnackbar(validationError);
      return;
    }

    // Show Loading
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildLoadingDialog("Assigning Task..."));

    try {
      final empResponse = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp_job.php'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (empResponse.statusCode != 200)
        throw Exception('Emp fetch fail (${empResponse.statusCode})');

      List<dynamic> employees = jsonDecode(empResponse.body);
      if (employees is! List) throw Exception("Emp data error");
      List<String> selectedUserIDs = _mapSelectedEmployeesToIDs(employees);
      if (selectedUserIDs.isEmpty && _selectedEmployees.isNotEmpty)
        throw Exception('Could not find IDs');

      List<Future<http.Response>> taskFutures =
          _buildTaskPostFutures(selectedUserIDs);
      final results = await Future.wait(taskFutures); // Wait for all posts
      if (!mounted) return;

      bool allSuccess = _processSaveTaskResults(results); // Process results
      Navigator.pop(context); // Pop loading

      if (allSuccess) {
        _clearForm();
        _showSuccessSnackbar('Task(s) assigned!');
        _fetchTasks();
      } else {
        _showErrorSnackbar('Some tasks failed. Check logs.', isWarning: true);
        _fetchTasks();
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      print('Save task error: $e');
      _showErrorSnackbar('Error assigning task: ${e.toString()}');
    }
  }

  // Helper for task form validation
  String? _validateTaskForm() {
    if (_moduleController.text.trim().isEmpty) return 'Module Name missing.';
    if (_taskController.text.trim().isEmpty) return 'Task Description missing.';
    if (_selectedEmployees.isEmpty) return 'Assignee missing.';
    if (_selectedDate == null) return 'Deadline missing.';
    if (!_isOnsiteTask && _addressController.text.trim().isEmpty)
      return 'Address missing for offsite task.';
    return null; // No error
  }

  // Helper to map selected employee names to IDs
  List<String> _mapSelectedEmployeesToIDs(List<dynamic> employees) {
    List<String> ids = [];
    for (String name in _selectedEmployees) {
      var emp = employees.firstWhere(
          (e) =>
              e is Map &&
              e['firstName'] == name &&
              e['usersTableUserID'] != null,
          orElse: () => null);
      if (emp != null) {
        String? uid = emp['usersTableUserID']?.toString();
        if (uid != null) ids.add(uid);
      } else
        print("Warn: ID for $name not found during save.");
    }
    return ids;
  }

  // Helper to build list of POST request Futures
  List<Future<http.Response>> _buildTaskPostFutures(List<String> userIDs) {
    List<Future<http.Response>> futures = [];
    final deadlineStr = _selectedDate!.toIso8601String().split('T')[0];
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    final addressStr = !_isOnsiteTask ? _addressController.text.trim() : null;

    for (var userID in userIDs) {
      final taskData = {
        'projectID': widget.projecid,
        'module': _moduleController.text.trim(),
        'task': _taskController.text.trim(),
        'userID': userID,
        'deadline': deadlineStr,
        'date': dateStr,
        'status': 'pending',
        'address': addressStr,
        'completeTime': null,
        'startDate': null,
        'distance': null,
        'petrolAllowance': null,
      };
      print("Sending Task: ${jsonEncode(taskData)}");
      futures.add(http
          .post(Uri.parse('http://192.168.29.211/hr_api/addtask.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(taskData))
          .timeout(const Duration(seconds: 15)));
    }
    return futures;
  }

  // Helper to process save task API results
  bool _processSaveTaskResults(List<http.Response> results) {
    bool allSuccess = true;
    for (var response in results) {
      print(
          'API Resp (${response.request?.url}): ${response.statusCode} - ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          var body = jsonDecode(response.body);
          if (body is Map && body['success'] == false) allSuccess = false;
        } catch (_) {}
      } else {
        allSuccess = false;
      }
    }
    return allSuccess;
  }

  // --- Direct Delete Task (NO confirmation dialog) ---
  Future<void> deleteTask(BuildContext context, int taskID) async {
    // Use state context directly for flag checks and setting state
    if (_isDeletingTask) {
      print("Delete already in progress.");
      return;
    }
    if (!mounted) return;

    setState(() {
      _isDeletingTask = true;
    });

    // Show progress indicator using state's helper
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildLoadingDialog("Deleting Task..."));

    try {
      print("Deleting task ID: $taskID via delete_subtask.php");
      // *** TARGET THE NEW DELETE ENDPOINT ***
      final response = await http
          .post(Uri.parse('http://192.168.29.211/hr_api/delete_subtask.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'taskID': taskID}))
          .timeout(const Duration(seconds: 12));

      if (!mounted) return; // Check after await
      Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          // ** Adapt check based on YOUR API's success response **
          if (jsonResponse is Map && jsonResponse['success'] == true) {
            _showSuccessSnackbar("Task deleted successfully.");
            // Remove from local paid set if deleted
            if (mounted) setState(() => _paidTaskIds.remove(taskID));
            _fetchTasks(); // Refresh list
          } else {
            String message = jsonResponse is Map
                ? jsonResponse['message']?.toString() ?? "API error"
                : "Invalid response";
            _showErrorSnackbar("Failed to delete: $message");
          }
        } catch (e) {
          _showErrorSnackbar("Error processing delete response.");
          print("Delete decode error: $e");
        }
      } else {
        _showErrorSnackbar(
            "Server error (${response.statusCode}) during delete.");
        print("Delete server error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showErrorSnackbar("Error deleting: ${e.toString()}");
      print("Delete network error: $e");
    } finally {
      // Use state's mounted check before setState
      if (mounted) {
        setState(() {
          _isDeletingTask = false;
        });
      } else
        _isDeletingTask = false;
    }
  }

  // --- New Function to call Email_Distance API ---
  Future<bool> _callEmailDistanceAPI(String taskIDString) async {
    // Ensure taskID is actually a string, although the caller should handle this.
    if (taskIDString == null || taskIDString.isEmpty) {
      print(
          "Error: Email_Distance API called with null or empty taskIDString.");
      return false;
    }

    final url = Uri.parse(
        'http://192.168.29.211/hr_api/Email_Distance.php'); // Use the specified API endpoint
    final headers = {'Content-Type': 'application/json'};
    // Send taskID as a string in JSON
    final body = jsonEncode({'taskID': taskIDString});

    print("--- Calling Email_Distance API for Task ID: $taskIDString ---");
    print("URL: $url");
    print("Body: $body");

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15)); // Add a timeout

      print("Email_Distance API Response Status: ${response.statusCode}");
      print("Email_Distance API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Assuming the API returns JSON with a success flag like the others
        try {
          final responseBody = jsonDecode(response.body);
          // ** IMPORTANT: Adapt this check based on the ACTUAL response of Email_Distance.php **
          if (responseBody is Map && responseBody['success'] == true) {
            print(
                "Email_Distance API call successful for Task ID: $taskIDString");
            return true; // Indicate success
          } else {
            String errorMsg = responseBody is Map
                ? responseBody['message']?.toString() ?? 'API indicated failure'
                : 'Non-standard success response';
            print(
                "Email_Distance API call failed (API Logic): $errorMsg for Task ID: $taskIDString");
            return false; // Indicate failure
          }
        } catch (e) {
          print(
              "Error decoding Email_Distance API response for Task ID $taskIDString: $e");
          return false;
        }
      } else {
        // Handle HTTP errors (4xx, 5xx)
        print(
            "Email_Distance API call failed (HTTP Error ${response.statusCode}) for Task ID: $taskIDString");
        return false; // Indicate failure
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      print("Error calling Email_Distance API for Task ID $taskIDString: $e");
      return false; // Indicate failure
    }
  }
  // --- End New Function ---

  // Handle Cash Out button press (with API Call structure)
  Future<void> _handleCashOut(
      BuildContext context, int taskID, double allowance) async {
    if (_isProcessingCashOut) return; // Debounce check
    if (!mounted) return;

    setState(() {
      _isProcessingCashOut = true;
    });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildLoadingDialog("Processing Payout..."));

    try {
      print(
          "--- Preparing API CALL: Mark payout paid for Task ID: $taskID, Amount: $allowance ---");

      // *** Call the record_payout API ***
      final response = await http
          .post(
            Uri.parse(
                'http://192.168.29.211/hr_api/record_payout.php'), // Endpoint to record payout
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'taskID': taskID,
              'amount': allowance
            }), // Send task ID and amount
          )
          .timeout(const Duration(seconds: 15)); // Set reasonable timeout

      if (!mounted) return; // Check mounted state *after* the await
      Navigator.pop(context); // Dismiss loading dialog FIRST

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // ** Adapt check based on YOUR record_payout.php API response **
        if (responseBody is Map && responseBody['success'] == true) {
          _showSuccessSnackbar(
              'Payout of ₹${allowance.toStringAsFixed(2)} recorded successfully!');

          // --- >>> Mark task as paid locally <<< ---
          if (mounted) {
            setState(() {
              _paidTaskIds.add(taskID);
            });
          }
          // --- >>> END <<<---

          // --- >>> Call the Email_Distance API AFTER successful payout recording <<< ---
          final String taskIDString =
              taskID.toString(); // Convert int taskID to String
          bool emailApiSuccess = await _callEmailDistanceAPI(taskIDString);

          if (!emailApiSuccess) {
            // Log the failure, maybe show a subtle warning later if needed
            print(
                "Warning: Email_Distance API call failed for task $taskIDString after successful payout.");
            // Optionally, show a different snackbar or log more formally
            _showErrorSnackbar(
                "Payout recorded, but email notification might have failed.",
                isWarning: true);
          }
          // --- >>> END ADDED CODE <<< ---

          // No need to call _fetchTasks() here anymore, as the local state (_paidTaskIds)
          // will hide the button immediately upon setState. A full refresh isn't required
          // unless the backend is the source of truth for the paid status.
        } else {
          // Handle payout recording failure
          String errorMsg = responseBody is Map
              ? responseBody['message']?.toString() ?? 'API Error'
              : 'Invalid API Response';
          _showErrorSnackbar('Failed to record payout: $errorMsg');
          print("Payout API Error Response: ${response.body}");
        }
      } else {
        // Handle payout server error
        _showErrorSnackbar(
            'Server Error (${response.statusCode}) recording payout.');
        print("Payout Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      // Handle general errors (network, timeout, etc.)
      if (!mounted) return;
      // Ensure loading dialog is dismissed on error too, if it hasn't been already
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showErrorSnackbar("Error during cash out process: ${e.toString()}");
      print("Error during Cash Out process: $e");
    } finally {
      // Always release the processing flag
      if (mounted) {
        setState(() {
          _isProcessingCashOut = false;
        });
      } else {
        _isProcessingCashOut = false; // Reset flag safely if not mounted
      }
    }
  }

  // --- UI Helper Methods ---

  int? _parseTaskId(String? id) => (id == null) ? null : int.tryParse(id);

  void _showErrorSnackbar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .removeCurrentSnackBar(); // Remove previous snackbar first
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: isWarning ? Colors.orange.shade800 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.fromLTRB(15, 5, 15, 10),
    ));
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Colors.white)))
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.fromLTRB(15, 5, 15, 10),
    ));
  }

  Dialog _buildLoadingDialog(String message) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: primary, strokeWidth: 3.0)),
              const SizedBox(width: 20),
              Text(message,
                  style: TextStyle(
                      fontFamily: 'NexaRegular',
                      fontSize: 16,
                      color: Colors.black87)),
            ],
          ),
        ),
      );

  void _openEmployeeSelectionScreen() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeSelectionScreen(
            projectid: widget.projecid,
            selectedEmployees: List.from(_selectedEmployees),
            onSelect: (names) {
              if (mounted)
                setState(() {
                  _selectedEmployees = names;
                  _updateSelectedEmployeesText();
                });
            },
          ),
        ),
      );

  void _updateSelectedEmployeesText() => _employeeTextFieldController.text =
      _selectedEmployees.isEmpty ? "" : _selectedEmployees.join(', ');

  void _clearForm() => setState(() {
        _moduleController.clear();
        _taskController.clear();
        _employeeTextFieldController.clear();
        _addressController.clear();
        _selectedDate = null;
        _selectedEmployees.clear();
        _isOnsiteTask = true;
      });

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
            title: Text(widget.projectName,
                style: const TextStyle(
                    fontFamily: 'NexaBold', color: Colors.white, fontSize: 20),
                overflow: TextOverflow.ellipsis),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 1.5,
            shadowColor: primary.withOpacity(0.3)),
        body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildAddSubtaskTab(screenWidth), _buildTasksListTab()]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(.06),
                offset: Offset(0, -1))
          ]),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
              child: TabBar(
                tabs: const [
                  Tab(
                      icon: Icon(Icons.add_task, size: 22),
                      text: 'Add Task',
                      height: 50),
                  Tab(
                      icon: Icon(Icons.view_list_rounded, size: 22),
                      text: 'View Tasks',
                      height: 50)
                ],
                labelColor: primary,
                unselectedLabelColor: Colors.grey[500],
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3.5,
                indicatorColor: primary,
                labelStyle:
                    const TextStyle(fontFamily: 'NexaBold', fontSize: 12.0),
                unselectedLabelStyle:
                    const TextStyle(fontFamily: 'NexaRegular', fontSize: 12.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Build Add Subtask Tab ---
  Widget _buildAddSubtaskTab(double screenWidth) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 10),
          Center(
              child: Text("Add New Project Task",
                  style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: 22,
                      color: Colors.grey.shade800))),
          const SizedBox(height: 30),
          _buildTextFieldLabel('Module Name'),
          Container(
              decoration: _inputBoxDecoration(),
              child: TextField(
                  controller: _moduleController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: primary,
                  style: _inputTextStyle(),
                  decoration: _inputDecoration(
                      hint: "e.g., UI Design",
                      icon: Icons.view_module_outlined))),
          const SizedBox(height: 20),
          _buildTextFieldLabel('Task Description'),
          Container(
              decoration: _inputBoxDecoration(),
              child: TextField(
                  controller: _taskController,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  cursorColor: primary,
                  style: _inputTextStyle(),
                  decoration: _inputDecoration(
                      hint: "Detailed description...",
                      icon: Icons.description_outlined))),
          const SizedBox(height: 20),
          _buildTextFieldLabel('Assign To Employee(s)'),
          Container(
              decoration: _inputBoxDecoration(),
              child: TextField(
                  controller: _employeeTextFieldController,
                  readOnly: true,
                  onTap: _openEmployeeSelectionScreen,
                  style: _inputTextStyle().copyWith(height: 1.4),
                  decoration: InputDecoration(
                      hintText: _employeeTextFieldController.text.isEmpty
                          ? "Click to select employees"
                          : null,
                      hintStyle:
                          _inputTextStyle().copyWith(color: Colors.grey[500]),
                      prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 10),
                          child: Icon(Icons.group_add_outlined,
                              color: primary.withOpacity(0.7), size: 20)),
                      prefixIconConstraints:
                          BoxConstraints(minHeight: 40, minWidth: 45),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 0)),
                  minLines: 1,
                  maxLines: 2)),
          const SizedBox(height: 20),
          _buildTextFieldLabel('Task Location'),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: _inputBoxDecoration().copyWith(color: Colors.white),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          color: primary.withOpacity(0.7), size: 20),
                      SizedBox(width: 8),
                      Text('Is Task On-Site?',
                          style: _inputTextStyle()
                              .copyWith(color: Colors.black54, fontSize: 15.5))
                    ]),
                    Row(children: [
                      Text(_isOnsiteTask ? 'On-Site' : 'Off-Site',
                          style: _inputTextStyle().copyWith(
                              color: _isOnsiteTask
                                  ? Colors.green.shade700
                                  : Colors.deepOrange.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Transform.scale(
                          scale: 0.8,
                          child: Switch(
                              value: _isOnsiteTask,
                              onChanged: (v) => setState(() {
                                    _isOnsiteTask = v;
                                    if (v) _addressController.clear();
                                  }),
                              activeColor: primary,
                              inactiveTrackColor: Colors.grey[300],
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap))
                    ])
                  ])),
          const SizedBox(height: 5),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (c, a) =>
                  SizeTransition(child: c, sizeFactor: a, axisAlignment: -1.0),
              child: !_isOnsiteTask
                  ? Padding(
                      key: ValueKey('address'),
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFieldLabel('Site Address'),
                            Container(
                                decoration: _inputBoxDecoration(),
                                child: TextField(
                                    controller: _addressController,
                                    maxLines: 3,
                                    minLines: 2,
                                    keyboardType: TextInputType.multiline,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    cursorColor: primary,
                                    style: _inputTextStyle(),
                                    decoration: _inputDecoration(
                                        hint: "Enter full site address",
                                        icon: Icons.location_city_outlined))),
                            const SizedBox(height: 20)
                          ]))
                  : SizedBox.shrink(key: ValueKey('noAddress'))),
          _buildTextFieldLabel('Deadline'),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: _inputBoxDecoration(),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.event_available_outlined,
                        color: primary.withOpacity(0.7), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            _selectedDate == null
                                ? 'Select date...'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: _inputTextStyle().copyWith(
                                fontSize: 15.5,
                                color: _selectedDate == null
                                    ? Colors.grey[500]
                                    : Colors.black87))),
                    IconButton(
                        icon: Icon(Icons.calendar_month_outlined,
                            color: primary, size: 24),
                        tooltip: "Choose Deadline",
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => _selectDate(context))
                  ])),
          const SizedBox(height: 40),
          Center(
              child: SizedBox(
            width: screenWidth * 0.8,
            height: 50,
            child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline_rounded, size: 22),
                label: Text('Assign Task',
                    style: TextStyle(fontSize: 16, fontFamily: 'NexaBold')),
                onPressed: savetask,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)))),
          )),
          const SizedBox(height: 30)
        ]));
  }

  // Helper widget for text field labels
  Widget _buildTextFieldLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label,
          style: TextStyle(
              fontSize: 15,
              fontFamily: "NexaBold",
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500)));
  // Helper for text field text style
  TextStyle _inputTextStyle() => const TextStyle(
      fontFamily: 'NexaRegular', fontSize: 16, color: Colors.black87);
  // Helper for standard InputDecoration
  InputDecoration _inputDecoration(
          {required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        icon: Padding(
            padding: EdgeInsets.only(left: 15),
            child: Icon(icon, color: primary.withOpacity(0.7), size: 20)),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      );
  // Helper for standard input Container decoration
  BoxDecoration _inputBoxDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: Offset(0, 2))
      ],
      border: Border.all(color: Colors.grey.shade200, width: 0.8));

  // Builds the content for the "Tasks List" tab
  Widget _buildTasksListTab() => _isLoadingTasks
      ? Center(child: CircularProgressIndicator(color: primary))
      : (tasks.isEmpty ? _buildEmptyState() : _buildTasksListView());

  // Builds the empty state view
  Widget _buildEmptyState() => Center(
          child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Consider adding a placeholder image if you have one
          // Image.asset('assets/images/empty_tasks.png', height: 150, color: Colors.grey[300]),
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 25),
          Text('No Tasks Here Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NexaBold',
                  color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Text('Assigned tasks for "${widget.projectName}"\nwill show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'NexaRegular',
                  color: Colors.grey[500],
                  height: 1.4)),
          const SizedBox(height: 30),
          OutlinedButton.icon(
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Refresh List'),
              onPressed: _fetchTasks,
              style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10)))
        ]),
      ));

  // Builds the Task List View - Modified Button Logic
  Widget _buildTasksListView() {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 18.0, bottom: 12),
          child: Text('Project Tasks',
              style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 20,
                  color: Colors.grey.shade800))),
      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final taskData = tasks[index];
            final status = taskData['status']?.toString() ?? 'unknown';
            final allowance = taskData['petrolAllowance'] as double?;
            final taskID = _parseTaskId(taskData['taskID']?.toString());
            final bool isPaid = taskID != null &&
                _paidTaskIds.contains(taskID); // Check if paid locally
            // final bool isPaidFromBackend = taskData['isPaid'] ?? false; // Use this if backend provides status

            String str(k, [d = 'N/A']) =>
                taskData[k]?.toString() ?? d; // Short helper

            Color bg = Colors.grey.shade100, tc = Colors.grey.shade700;
            FontWeight fw = FontWeight.w500;
            if (status == 'completed') {
              bg = Colors.green.shade50;
              tc = Colors.green.shade800;
              fw = FontWeight.w600;
            } else if (status == 'pending') {
              bg = Colors.orange.shade50;
              tc = Colors.orange.shade700;
              fw = FontWeight.w600;
            } else if (status == 'start_in') {
              bg = Colors.blue.shade50;
              tc = Colors.blue.shade700;
              fw = FontWeight.w600;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 1.5,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200, width: 0.6)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(str('module').toUpperCase(),
                                      style: TextStyle(
                                          fontFamily: 'NexaBold',
                                          fontSize: 16,
                                          color: Colors.black.withOpacity(0.85),
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2))),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                  str('status')
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontFamily: 'NexaBold',
                                      fontSize: 10.5,
                                      color: tc,
                                      fontWeight: fw,
                                      letterSpacing: 0.4)))
                        ]),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10.0, top: 2),
                        child: Text(str('task', 'No description'),
                            style: const TextStyle(
                                fontFamily: 'NexaRegular',
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4))),
                    Divider(color: Colors.grey[200], height: 1, thickness: 0.8),
                    const SizedBox(height: 8),
                    Wrap(spacing: 12.0, runSpacing: 6.0, children: [
                      _buildInfoChip(
                          status == 'completed'
                              ? Icons.check_circle_outline
                              : Icons.person_pin_circle_outlined,
                          '${status == 'completed' ? 'By' : 'To'}: ${str('firstName', 'Unknown')} (${str('deptName', 'N/A')})'),
                      _buildInfoChip(Icons.calendar_today_outlined,
                          'Due: ${str('deadline', 'N/A')}'),
                      if (status == 'completed' &&
                          allowance != null &&
                          allowance > 0)
                        _buildInfoChip(Icons.local_gas_station_outlined,
                            'Allowance: ₹${allowance.toStringAsFixed(2)}',
                            iconColor: Colors.teal.shade600,
                            textColor: Colors.teal.shade800,
                            isBold: true)
                      else if (status == 'completed')
                        _buildInfoChip(
                            Icons.money_off_csred_outlined, 'No allowance',
                            iconColor: Colors.grey.shade400,
                            textColor: Colors.grey.shade600)
                    ]),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Wrap(spacing: 4.0, children: [
                          // --- MODIFIED: Conditional Payout Action ---
                          if (status == 'completed' &&
                              allowance != null &&
                              allowance > 0)
                            // Check if taskID is valid AND if it's in the locally paid set
                            (taskID != null && isPaid)
                                ? Padding(
                                    // Show "Paid" text if already paid in this session
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical:
                                            9.5), // Adjust padding to align roughly
                                    child: Text(
                                      'Paid: ₹${allowance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: 'NexaBold'),
                                    ),
                                  )
                                : TextButton.icon(
                                    // Show Cash Out button if not paid yet
                                    icon: Icon(Icons.paid_outlined,
                                        size: 18, color: Colors.teal.shade700),
                                    label: Text('Cash Out',
                                        style: TextStyle(
                                            color: Colors.teal.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    // Enable button only if taskID valid AND not currently processing cash out
                                    onPressed: taskID != null &&
                                            !_isProcessingCashOut
                                        ? () => _handleCashOut(
                                            context, taskID, allowance)
                                        : null, // Disable if processing or taskID null
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            side: BorderSide(
                                                color: Colors.teal.shade100)))),
                          // --- Delete Button (remains the same) ---
                          IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: Colors.red.shade300),
                              tooltip: "Delete Task",
                              iconSize: 22,
                              splashRadius: 18,
                              padding: EdgeInsets.all(6),
                              constraints: BoxConstraints(),
                              // Enable only if taskID valid and not deleting
                              onPressed: taskID != null && !_isDeletingTask
                                  ? () => deleteTask(context, taskID)
                                  : null,
                              visualDensity: VisualDensity.compact),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // Helper widget for info chips
  Widget _buildInfoChip(IconData icon, String text,
          {Color? iconColor, Color? textColor, bool isBold = false}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor ?? Colors.grey.shade500, size: 14),
        SizedBox(width: 5),
        Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: isBold ? 'NexaBold' : 'NexaRegular',
                    color: textColor ?? Colors.grey.shade600,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
                maxLines: 2))
      ]);
} // End _subtaskState

// --- EmployeeSelectionScreen Class (UI Enhanced) ---
class EmployeeSelectionScreen extends StatefulWidget {
  final List<String> selectedEmployees;
  final Function(List<String>) onSelect;
  final String projectid;
  const EmployeeSelectionScreen(
      {Key? key,
      required this.selectedEmployees,
      required this.onSelect,
      required this.projectid})
      : super(key: key);
  @override
  _EmployeeSelectionScreenState createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  List<Employee> _a = [];
  late List<String> _t;
  bool _l = true;
  String _e = '';
  final TextEditingController _s = TextEditingController();
  List<Employee> _f = [];
  @override
  void initState() {
    super.initState();
    _t = List.from(widget.selectedEmployees);
    _fetchEmployees();
    _s.addListener(_filter);
  }

  @override
  void dispose() {
    _s.removeListener(_filter);
    _s.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;
    setState(() {
      _l = true;
      _e = '';
    });
    try {
      final r = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp_job.php'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (r.statusCode != 200) throw Exception('Status ${r.statusCode}');
      final d = jsonDecode(r.body);
      if (d is List) {
        final emps = d
            .whereType<Map>()
            .where((m) =>
                m['usersTableUserID'] != null &&
                m['firstName'] != null &&
                m['deptName'] != null)
            .map((m) => Employee(
                employeeUserID: m['usersTableUserID'].toString(),
                firstName: m['firstName'].toString(),
                deptName: m['deptName'].toString()))
            .toList();
        emps.sort((x, y) =>
            x.firstName.toLowerCase().compareTo(y.firstName.toLowerCase()));
        if (mounted)
          setState(() {
            _a = emps;
            _f = emps;
            _l = false;
          });
      } else
        throw Exception("Data not List");
    } catch (err) {
      if (mounted)
        setState(() {
          _l = false;
          _e = 'Load Error.\n$err';
        });
    }
  }

  void _filter() {
    if (!mounted) return;
    final q = _s.text.toLowerCase();
    setState(() {
      _f = _a
          .where((e) =>
              e.firstName.toLowerCase().contains(q) ||
              e.deptName.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color p = const Color(0xffeef444c);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: const Text('Select Employees'),
            backgroundColor: p,
            foregroundColor: Colors.white,
            elevation: 1.0,
            actions: [
              if (!_l && _e.isEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                        onPressed: () {
                          widget.onSelect(_t);
                          Navigator.pop(context);
                        },
                        child: Text("DONE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15))))
            ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                  controller: _s,
                  style: TextStyle(fontSize: 15.5),
                  decoration: InputDecoration(
                      hintText: 'Search name or dept...',
                      hintStyle:
                          TextStyle(fontSize: 15, color: Colors.grey[500]),
                      prefixIcon: Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, right: 8.0),
                          child: Icon(Icons.search,
                              color: Colors.grey[600], size: 20)),
                      prefixIconConstraints:
                          BoxConstraints(minHeight: 36, minWidth: 36),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: p, width: 1.5)),
                      isDense: true,
                      suffixIcon: _s.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.grey[600], size: 18),
                              padding: EdgeInsets.zero,
                              splashRadius: 18,
                              onPressed: _s.clear)
                          : null))),
          Expanded(child: _buildBodyContent(p))
        ]));
  }

  Widget _buildBodyContent(Color p) {
    if (_l)
      return Center(child: CircularProgressIndicator(color: p, strokeWidth: 3));
    if (_e.isNotEmpty)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_off_rounded,
                    color: Colors.orange.shade300, size: 40),
                SizedBox(height: 15),
                Text(_e,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                SizedBox(height: 25),
                OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text('Retry'),
                    onPressed: _fetchEmployees,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: p,
                        side: BorderSide(color: p.withOpacity(0.5))))
              ])));
    if (_f.isEmpty && _a.isNotEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 50, color: Colors.grey[300]),
        SizedBox(height: 15),
        Text('No matches for "${_s.text}"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]))
      ]));
    if (_a.isEmpty)
      return const Center(
          child: Text('No employees found.',
              style: TextStyle(fontSize: 16, color: Colors.grey)));
    return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
        itemCount: _f.length,
        itemBuilder: (c, i) {
          final emp = _f[i];
          final sel = _t.contains(emp.firstName);
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: CheckboxListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  contentPadding: EdgeInsets.only(left: 8, right: 12),
                  title: Text(emp.firstName,
                      style: const TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(emp.deptName,
                      style: TextStyle(
                          fontFamily: 'NexaRegular',
                          fontSize: 12.5,
                          color: Colors.grey[600])),
                  value: sel,
                  onChanged: (v) {
                    if (!mounted) return;
                    setState(() {
                      if (v == true) {
                        if (!_t.contains(emp.firstName)) _t.add(emp.firstName);
                      } else {
                        _t.remove(emp.firstName);
                      }
                    });
                  },
                  activeColor: p,
                  controlAffinity: ListTileControlAffinity.leading,
                  checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  dense: true,
                  secondary: Icon(
                      sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: sel ? p.withOpacity(0.9) : Colors.grey[300],
                      size: 20)));
        });
  }
}

// --- Payment Options Dialog (Kept for reference, not actively called by Cash Out) ---
// This function remains unused by the current Cash Out logic but is kept here.
void _showPaymentOptionsDialog(BuildContext context, double allowance) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final p = const Color(0xffeef444c);
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Payment Options',
                  style: TextStyle(
                      fontFamily: 'NexaBold', fontSize: 18, color: p)),
              const SizedBox(height: 10),
              Text('Allowance: ₹${allowance.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'NexaRegular',
                      color: Colors.black54)),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                  icon: Icon(Icons.money_outlined, size: 18),
                  label: const Text('Confirm Cash Payment'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // To make this work, you would need to pass the taskID
                    // to this dialog and then call the actual cash out handler.
                    // Example: context.read<_subtaskState>()._handleCashOut(context, taskID, allowance);
                    print(
                        "Confirm Cash Payment pressed - requires Task ID and context access to call _handleCashOut");
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 15, fontFamily: 'NexaBold'))),
              const SizedBox(height: 12),
              TextButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 14, fontFamily: 'NexaRegular'))),
            ],
          ),
        ),
      );
    },
  );
}
