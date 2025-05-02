import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalaryPage extends StatefulWidget {
  final String employeeId;

  SalaryPage({required this.employeeId});

  @override
  _SalaryPageState createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  // Text Editing Controllers
  final TextEditingController bonusController = TextEditingController(text: '0.00'); // Default to 0
  final TextEditingController deductionController = TextEditingController(text: '0.00'); // Default to 0
  final TextEditingController netSalaryController = TextEditingController();
  final TextEditingController basicsalaryController = TextEditingController();
  final TextEditingController cashoutpointsController = TextEditingController(text: '0.00'); // Default to 0
  final TextEditingController monthController = TextEditingController(); // For displaying the selected month

  // State variables
  DateTime? _selectedDate;
  double _cashoutPoints = 0.0;
  bool _isLoadingDeductions = false; // To show loading state

  // UI Colors
  final Color primary = Colors.red;

  @override
  void initState() {
    super.initState();
    // Fetch initial data when the page loads
    fetchEmployeeData(); // Fetch basic salary
    _fetchCashoutPoints(); // Fetch cashout points
     // Set initial texts for controllers that might not be fetched immediately
     bonusController.text = '0.00';
     deductionController.text = '0.00';
     cashoutpointsController.text = '0.00';

  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    bonusController.dispose();
    deductionController.dispose();
    netSalaryController.dispose();
    basicsalaryController.dispose();
    cashoutpointsController.dispose();
    monthController.dispose();
    super.dispose();
  }

  // --- Data Fetching Methods ---

  // Fetches employee's basic salary
  Future<void> fetchEmployeeData() async {
    try {
      // API endpoint to get employee details (including basic salary)
      final response = await http
          .get(Uri.parse('http://192.168.29.211/hr_api/showemp.php')); // Use your actual API endpoint

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Find the specific employee's data using widget.employeeId
        final Map<String, dynamic>? employeeData = jsonData.firstWhere(
              (employee) =>
          employee['userID'].toString() == widget.employeeId.toString(),
          orElse: () => null, // Return null if not found
        );

        if (employeeData != null && employeeData['netSalary'] != null) {
          // Parse the netSalary (treat as basic for this context)
          double basicSalary = 0.0;
           if (employeeData['netSalary'] is int) {
             basicSalary = (employeeData['netSalary'] as int).toDouble();
           } else if (employeeData['netSalary'] is double) {
              basicSalary = employeeData['netSalary'];
           } else if (employeeData['netSalary'] is String) {
             basicSalary = double.tryParse(employeeData['netSalary']) ?? 0.0;
           }

          setState(() {
            // Update the basic salary controller
            basicsalaryController.text = basicSalary.toStringAsFixed(2);
          });
        } else {
          print('Employee data or netSalary not found for ID: ${widget.employeeId}');
           setState(() {
             basicsalaryController.text = '0.00'; // Set default if not found
           });
          // Optional: Show a message to the user
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Could not fetch basic salary.'),
               backgroundColor: Colors.orange[700],
             ),
           );
        }
      } else {
        throw Exception('Failed to load employee data (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching employee data: $e');
       setState(() {
          basicsalaryController.text = '0.00'; // Set default on error
       });
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching basic salary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetches employee's available cashout points
  Future<void> _fetchCashoutPoints() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/fetchpoints.php'), // Your points API endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userID': widget.employeeId}),
      );

      print('Fetching points for employee ID: ${widget.employeeId}');
      print('Points API Response Status: ${response.statusCode}');
      print('Points API Response Body: ${response.body}');

      if (response.statusCode == 200) {
         final dynamic decodedBody = json.decode(response.body);

         // Check if the response is a List or Map and handle accordingly
          Map<String, dynamic>? userData;
          if (decodedBody is List && decodedBody.isNotEmpty) {
             // Assuming the first element contains the data or error message
             if (decodedBody[0] is Map<String, dynamic>) {
               userData = decodedBody[0];
             }
           } else if (decodedBody is Map<String, dynamic>) {
            // Handle cases where the API might directly return the user object or an error map
            userData = decodedBody;
          }


         if (userData != null && userData['success'] != false && userData.containsKey('cashout')) {
            // Extract cashout points
            final totalPoints = double.tryParse(userData['cashout']?.toString() ?? '0.0') ?? 0.0;
            print('Points fetched: $totalPoints');
            setState(() {
              _cashoutPoints = totalPoints;
              cashoutpointsController.text = totalPoints.toStringAsFixed(2);
            });
          } else {
            // Handle errors reported by the API or missing 'cashout' key
             String errorMessage = userData?['message'] ?? 'No points data found or API error.';
            print('Error fetching points: $errorMessage');
            setState(() {
              _cashoutPoints = 0.0;
              cashoutpointsController.text = '0.00';
            });
             // Optional: Show specific error from API if available
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Could not fetch points: $errorMessage'),
                 backgroundColor: Colors.orange[700],
               ),
             );
          }

      } else {
         throw Exception('Failed to fetch points: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching points: $e');
      setState(() {
        _cashoutPoints = 0.0;
        cashoutpointsController.text = '0.00';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching points: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 // Fetches monthly deductions based on selected month
  Future<void> _fetchMonthlyDeduction(DateTime selectedMonthDate) async {
    setState(() {
      _isLoadingDeductions = true; // Show loading indicator
       deductionController.text = '0.00'; // Clear previous while loading
    });

    final String formattedMonth = DateFormat('yyyy-MM').format(selectedMonthDate);
    final String apiUrl = 'http://192.168.29.211/hr_api/Leave_Auto.php'; // Your PHP API URL

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching deductions for $formattedMonth...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'month': formattedMonth}),
      );

      print('Fetching deductions API for month: $formattedMonth');
      print('Deduction API Response Status: ${response.statusCode}');
      print('Deduction API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);

        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
           final Map<String, dynamic> allEmployeeData = Map<String, dynamic>.from(decodedResponse['data']); // Cast safely
           final String currentEmployeeIdString = widget.employeeId.toString();

          if (allEmployeeData.containsKey(currentEmployeeIdString)) {
            final employeeMonthData = allEmployeeData[currentEmployeeIdString];
             final dynamic deductionValue = employeeMonthData['deduction'];
             double deductionAmount = 0.0;

            // Parse deduction value safely (could be int, double, string)
             if (deductionValue != null) {
                if (deductionValue is int) {
                 deductionAmount = deductionValue.toDouble();
                } else if (deductionValue is double) {
                  deductionAmount = deductionValue;
                } else if (deductionValue is String) {
                  deductionAmount = double.tryParse(deductionValue) ?? 0.0;
               }
             }

            print('Deduction fetched for employee ${widget.employeeId}: $deductionAmount');
             setState(() {
               deductionController.text = deductionAmount.toStringAsFixed(2);
             });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deduction loaded: ₹${deductionAmount.toStringAsFixed(2)}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            print('No deduction data found for employee ID ${widget.employeeId} for $formattedMonth.');
             setState(() {
               deductionController.text = '0.00'; // Default if no data for this user
             });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No deduction details found for this employee for $formattedMonth.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        } else {
           print('API Error (Deductions): ${decodedResponse['message']}');
            setState(() {
             deductionController.text = '0.00'; // Default on API reported error
           });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get deductions: ${decodedResponse['message'] ?? 'Unknown API error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
         print('HTTP Error fetching deductions: ${response.statusCode}');
         setState(() {
             deductionController.text = '0.00'; // Default on HTTP error
          });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch deductions (Server Error ${response.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching/parsing deductions: $e');
       setState(() {
            deductionController.text = '0.00'; // Default on exception
        });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing deductions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingDeductions = false; // Hide loading indicator
      });
    }
  }


  // --- UI Event Handlers ---

  // Opens the Date Picker to select Month/Year
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // User can only select past/current months
      initialEntryMode: DatePickerEntryMode.calendarOnly, // Can be calendar or input
      // You might want to customize the picker further
      // initialDatePickerMode: DatePickerMode.year, // Start with year selection
      helpText: 'Select Salary Month',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,        // Header background
              onPrimary: Colors.white,  // Header text
              surface: Colors.white,    // Calendar background
              onSurface: Colors.black, // Calendar text
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    // If a date was picked and it's different from the current selection
    if (picked != null && (_selectedDate == null || picked.year != _selectedDate!.year || picked.month != _selectedDate!.month)) {
      setState(() {
        // Store the selected date (normalize to the 1st of the month for consistency)
        _selectedDate = DateTime(picked.year, picked.month, 1);
        // Update the month text field display
        monthController.text = DateFormat('MMMM yyyy').format(_selectedDate!);
        // Clear previous calculated salary and fetched deduction when month changes
        netSalaryController.text = '';
        deductionController.text = '0.00'; // Reset deduction field
      });
      // --- Trigger the API call to fetch deductions for the NEWLY selected month ---
      _fetchMonthlyDeduction(_selectedDate!);
      // --- ---
    }
  }

  // Calculates the Net Salary based on current inputs
  void calculateSalary() {
     // Validate if month is selected
     if (_selectedDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Please select a month first.'),
           backgroundColor: Colors.orange[700],
         ),
       );
       return;
     }

    // Parse values from controllers, defaulting to 0.0 if parsing fails
    double basicSalary = double.tryParse(basicsalaryController.text) ?? 0.0;
    double bonus = double.tryParse(bonusController.text) ?? 0.0;
    // IMPORTANT: Uses the current value in the text field (fetched or manually edited)
    double deduction = double.tryParse(deductionController.text) ?? 0.0;
    double cashoutPointsValue = double.tryParse(cashoutpointsController.text) ?? 0.0;

    // Perform the calculation
    double calculatedNetSalary = basicSalary + bonus - deduction + cashoutPointsValue;

    // Update the Net Salary display
    setState(() {
      netSalaryController.text = calculatedNetSalary.toStringAsFixed(2);
    });

     // Optionally, immediately try to save/update the calculated salary
     // _saveSalary(calculatedNetSalary); // Uncomment if you want to save on calculation
  }

  // --- Optional: Method to save the calculated salary (if needed separate from calculation) ---
  Future<void> _saveSalary(double finalNetSalary) async {
    // Check if month is selected before saving
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a month before saving.'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    // Add validation for other fields if needed

     final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!); // Or just use yyyy-MM if backend expects that


    final String apiUrl = 'http://192.168.29.211/hr_api/changecashout.php'; // Endpoint to save/update salary record
    // Note: Your current API 'changecashout.php' might need adjustment
    // It seems to only update based on employeeId and netSalary.
    // A better API might accept employeeId, month, basic, bonus, deduction, cashout, net_salary

    print("Attempting to save salary...");
    print("Employee ID: ${widget.employeeId}");
    print("Selected Month Date: $formattedDate"); // Make sure this aligns with backend needs
    print("Basic Salary: ${basicsalaryController.text}");
    print("Bonus: ${bonusController.text}");
    print("Deduction: ${deductionController.text}");
    print("Cashout Points: ${cashoutpointsController.text}");
    print("Calculated Net Salary: $finalNetSalary");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        // ---- IMPORTANT ----
        // Adjust the body based on what your save/update API expects.
        // The current 'changecashout.php' structure seems limited.
        // You might need a new API or modify the existing one.
        // Example assuming a more comprehensive API:
        body: jsonEncode({
          "employeeId": widget.employeeId,
          "salary_month": DateFormat('yyyy-MM').format(_selectedDate!), // Send YYYY-MM
          "basic_salary": double.tryParse(basicsalaryController.text) ?? 0.0,
          "bonus": double.tryParse(bonusController.text) ?? 0.0,
          "deductions": double.tryParse(deductionController.text) ?? 0.0,
          "cashout_points_value": double.tryParse(cashoutpointsController.text) ?? 0.0,
          "netSalary": finalNetSalary,
          // Add any other fields your backend requires for saving a monthly record
        }),
         // Using the OLD API structure for now (might just update a single field):
         // body: jsonEncode({
         //   "employeeId": widget.employeeId,
         //   "netSalary": finalNetSalary,
         // }),
         // ---- ------------ ----
      );

      print("Save Salary API Status: ${response.statusCode}");
      print("Save Salary API Body: ${response.body}");


      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success'] == true || resBody['message'] != null) { // Adapt based on your API's success response
          print('Server Save Success: ${resBody['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resBody['message'] ?? 'Salary saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
           print('Server Save Error: ${resBody['error'] ?? resBody['message'] ?? 'Unknown error'}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving salary: ${resBody['error'] ?? resBody['message'] ?? 'Unknown server error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
         print('HTTP error saving salary: ${response.statusCode}, body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save salary (Error ${response.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Network error during save: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error saving salary. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Salary Calculation', // More specific title
          style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Optional Image Header
            Container(
              width: double.infinity, // Take full width
              height: 180, // Adjust height as needed
              margin: EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                   image: AssetImage('assets/images/salpg.jpg'), // Make sure path is correct
                   fit: BoxFit.cover,
                ),
                boxShadow: [ // Subtle shadow
                   BoxShadow(
                     color: Colors.black.withOpacity(0.2),
                     blurRadius: 5,
                     offset: Offset(0, 3),
                  ),
                ],
              ),
               // You could overlay text if needed:
               // child: Center(child: Text("Employee ID: ${widget.employeeId}", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),

            // Title Section
             Text(
               'Employee Salary Details (ID: ${widget.employeeId})',
               style: TextStyle(
                 fontSize: 22.0,
                 fontFamily: "NexaBold",
                 color: Colors.black87,
               ),
             ),
            SizedBox(height: 20.0), // Increased spacing

            // --- Input Fields ---

             _buildSalaryField(
              title: "Basic Salary",
              controller: basicsalaryController,
              icon: Icons.currency_rupee_rounded,
              hint: "Fetched Basic Salary",
              enabled: false, // Usually not editable by user here
             ),

            _buildMonthSelector(), // Month selection field

            _buildSalaryField(
              title: "Bonus",
              controller: bonusController,
              icon: Icons.wallet_giftcard_rounded,
              hint: "Enter Bonus Amount",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enabled: true,
            ),

             _buildSalaryField(
              title: "Deductions",
              controller: deductionController,
              icon: Icons.arrow_downward_rounded,
              hint: _isLoadingDeductions ? "Loading..." : "Enter or Fetch Deductions",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enabled: !_isLoadingDeductions, // Disable while loading
              isLoading: _isLoadingDeductions, // Pass loading state
             ),

             _buildSalaryField(
               title: "Cashout Points Value",
               controller: cashoutpointsController,
               icon: Icons.star_outline_rounded, // Changed Icon slightly
               hint: "Fetched Points Value",
               enabled: false, // Points usually fetched, not edited
             ),

            SizedBox(height: 24.0),

            // --- Calculate Button ---
            SizedBox( // Ensure button stretches
              width: double.infinity,
              child: ElevatedButton(
                onPressed: calculateSalary, // Calls the calculation logic
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: EdgeInsets.symmetric(vertical: 14), // Adjust padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // More rounded
                  ),
                  elevation: 5, // Add shadow
                ),
                child: Text(
                  'Calculate Net Salary',
                  style: TextStyle(fontSize: 18.0, color: Colors.white, fontFamily: "NexaBold"),
                ),
              ),
            ),

            SizedBox(height: 24.0),

             // --- Net Salary Display ---
             Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [ // Subtle shadow
                  BoxShadow(
                     color: Colors.grey.withOpacity(0.3),
                     spreadRadius: 1,
                     blurRadius: 4,
                     offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculated Net Salary:',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontFamily: "NexaBold",
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                     // Display calculated salary or placeholder
                     netSalaryController.text.isNotEmpty
                         ? '₹ ${netSalaryController.text}'
                         : '₹ --.--',
                     style: TextStyle(
                      fontSize: 28.0, // Larger font for result
                      fontWeight: FontWeight.bold,
                      color: primary, // Use primary color for emphasis
                      fontFamily: "NexaBold",
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15.0),

             // --- Optional Save Button ---
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                 // Trigger save only if net salary has been calculated
                onPressed: netSalaryController.text.isNotEmpty
                    ? () {
                       double? finalSalary = double.tryParse(netSalaryController.text);
                       if (finalSalary != null) {
                         _saveSalary(finalSalary); // Call the save function
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Cannot save invalid salary amount.'),
                             backgroundColor: Colors.red,
                           ),
                         );
                       }
                     }
                   : null, // Disable button if net salary not calculated
                 style: ElevatedButton.styleFrom(
                  backgroundColor: netSalaryController.text.isNotEmpty ? Colors.green : Colors.grey, // Color indicates state
                   padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                   elevation: 3,
                ),
                 child: Text(
                  'Save Salary Record',
                   style: TextStyle(fontSize: 17.0, color: Colors.white, fontFamily: "NexaRegular"),
                ),
              ),
            ),
             SizedBox(height: 20.0), // Bottom padding

          ],
        ),
      ),
    );
  }

   // --- Reusable Widget Builders ---

  // Helper to build the standard input field sections
  Widget _buildSalaryField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.number,
    bool isLoading = false, // Added for deduction field visual cue
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontFamily: "NexaBold", color: Colors.black87),
          ),
        ),
        Container(
          width: double.infinity, // Take full width
          height: 55, // Standard height
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[200], // Grey out if disabled
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8, // Softer shadow
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // Adjusted padding
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22), // Slightly larger icon
                SizedBox(width: 15), // Increased spacing
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: keyboardType,
                    cursorColor: primary,
                    style: TextStyle(fontSize: 16, color: enabled ? Colors.black : Colors.grey[700]),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(color: Colors.grey[500]), // Lighter hint text
                    ),
                  ),
                ),
                 // Show a loading indicator for the deduction field if needed
                 if (isLoading)
                  Padding(
                     padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                       ),
                    ),
                   )
              ],
            ),
          ),
        ),
        SizedBox(height: 18.0), // Standard spacing between fields
      ],
    );
  }

  // Specific widget for the Month Selector
  Widget _buildMonthSelector() {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
          child: Text(
            "Salary Month",
            style: TextStyle(fontSize: 16, fontFamily: "NexaBold", color: Colors.black87),
          ),
        ),
        GestureDetector(
          onTap: () => _selectDate(context), // Open date picker on tap
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: primary, size: 22),
                  SizedBox(width: 15),
                  Expanded(
                     // Use a TextField for display, but disable direct input
                     child: AbsorbPointer( // Makes the text field non-interactive directly
                      child: TextField(
                        controller: monthController, // Displays the selected month
                        readOnly: true, // Prevents keyboard from appearing
                        style: TextStyle(fontSize: 16, color: Colors.black),
                         decoration: InputDecoration(
                           contentPadding: EdgeInsets.symmetric(vertical: 10),
                           border: InputBorder.none,
                           hintText: "Select Month",
                           hintStyle: TextStyle(color: Colors.grey[500]),
                         ),
                      ),
                     ),
                  ),
                   Icon(Icons.arrow_drop_down, color: Colors.grey[600]), // Dropdown indicator
                 ],
              ),
            ),
          ),
        ),
        SizedBox(height: 18.0),
      ],
    );
  }
}