import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_hr/employee/employeedrawer.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class SalaryScreen extends StatefulWidget {
  final String employeeId;

  const SalaryScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  _SalaryScreenState createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with SingleTickerProviderStateMixin {
  final Color primary = const Color(0xffeef444c);
  String employeeName = "";
  String selectedMonth =
  DateFormat('yyyy-MM').format(DateTime.now()); // Default to current month
  Map<String, dynamic> salaryData = {};
  bool isLoading = true;

  // For PDF download animation
  bool isDownloading = false;
  bool isDownloaded = false;
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  List<String> availableMonths = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(_controller);

    _fetchEmployeeData();
    _fetchSalaryData(); // Fetch salary data on init
    _fetchAvailableMonths(); // Fetch available months
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeData() async {
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
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employee data: $e')));
    }
  }

  Future<void> _fetchSalaryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/get_salary.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          // Find the salary record for the selected month and user ID
          final List<dynamic> salaryRecords = data['data'];
          final salaryRecord = salaryRecords.firstWhere(
                (record) {
              // Format the record date to 'yyyy-MM' for comparison
              String recordDateFormatted = DateFormat('yyyy-MM')
                  .format(DateTime.parse(record['record_date']));
              return record['userID'] == widget.employeeId &&
                  recordDateFormatted == selectedMonth;
            },
            orElse: () => null,
          );

          if (salaryRecord != null) {
            setState(() {
              salaryData = salaryRecord;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No salary record found for this month.')),
            );
            setState(() {
              salaryData = {};
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load salary data')));
          setState(() {
            salaryData = {};
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load salary data')));
        setState(() {
          salaryData = {};
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching salary data: $e')));
      setState(() {
        salaryData = {};
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAvailableMonths() async {
    try {
      final url = Uri.parse('http://192.168.29.211/hr_api/get_salary.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          final List<dynamic> salaryRecords = data['data'];

          // Extract unique months from the record_date field
          Set<String> months = salaryRecords.map((record) {
            DateTime recordDate = DateTime.parse(record['record_date']);
            return DateFormat('yyyy-MM').format(recordDate);
          }).toSet();

          // Filter months to include only those where the userID matches
          Set<String> userMonths = salaryRecords
              .where((record) => record['userID'] == widget.employeeId)
              .map((record) {
            DateTime recordDate = DateTime.parse(record['record_date']);
            return DateFormat('yyyy-MM').format(recordDate);
          }).toSet();

          // Convert to list and sort
          List<String> sortedMonths = userMonths.toList()
            ..sort((a, b) => b.compareTo(a));

          setState(() {
            availableMonths = sortedMonths;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load salary data')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load salary data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching salary data: $e')));
    }
  }

  void _selectMonth(String month) {
    setState(() {
      selectedMonth = month;
    });
    _fetchSalaryData(); // Fetch data when month changes
  }

  String _getMonthName(String yearMonth) {
    try {
      DateTime dateTime = DateFormat('yyyy-MM').parse(yearMonth);
      return DateFormat('MMMM \n yyyy')
          .format(dateTime); // Format to "Month Year" (e.g., "January 2024")
    } catch (e) {
      return "Invalid Date"; // Handle invalid date formats
    }
  }

  void _startDownload() {
    if (isDownloading || isDownloaded) return;

    setState(() {
      isDownloading = true;
      isDownloaded = false;
    });
    _controller.repeat(reverse: true);

    // Simulate download process
    Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (timer.tick >= 10) {
        timer.cancel();
        _generatePdf();
        setState(() {
          isDownloading = false;
          isDownloaded = true;
        });
        _controller.stop();

        // Reset after 3 seconds
        Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              isDownloaded = false;
            });
          }
        });
      }
    });
  }

  Future<void> _generatePdf() async {
    if (salaryData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No salary data available for this month.')));
      return; // Don't generate PDF if there's no data
    }

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Salary Slip',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Employee Name: $employeeName'),
                pw.Text('Employee ID: ${widget.employeeId}'),
                pw.Text('Month: ${_getMonthName(selectedMonth)}'),
                pw.Divider(),
                pw.Text(
                    'Total Salary: ${salaryData['total_salary'] ?? 'N/A'}'), // access salary directly
                pw.SizedBox(height: 20),
                pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
              ],
            );
          },
        ),
      );

      final directory = Directory('/storage/emulated/0/Download/salary/');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath =
          '${directory.path}/salary_${selectedMonth.replaceAll(' ', '_')}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('PDF saved to $filePath')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Widget _buildMonthCard(String month) {
    final monthName = _getMonthName(month);
    return GestureDetector(
      onTap: () => _selectMonth(month),
      child: Container(
        width: 120, // Wider card for full month name
        margin: EdgeInsets.symmetric(horizontal: 2),
        child: Card(
          color: selectedMonth == month ? Colors.red : Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: selectedMonth == month ? 5 : 2,
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Center(
              child: Text(
                monthName, // Display full month name
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selectedMonth == month ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text("Salary Details",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.normal)),
            backgroundColor: primary),
        drawer: MyDrawer(
          employeeId: widget.employeeId,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text("Salary Details",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.normal)),
          backgroundColor: primary),
      drawer: MyDrawer(
        employeeId: widget.employeeId,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Month/Year:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: availableMonths
                    .map((month) => _buildMonthCard(month))
                    .toList(),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 7,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Employee Name: $employeeName",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                        "Total Salary: ${salaryData.isNotEmpty ? salaryData['total_salary'] ?? 'N/A' : 'N/A'}"), // Display the salary
                    SizedBox(height: 20),
                    Center(
                      child: _buildDownloadButton(),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: isDownloading || isDownloaded ? 180 : 180,
      height: 50,
      decoration: BoxDecoration(
        color: isDownloaded ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _startDownload,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: isDownloaded
                      ? Icon(Icons.check, color: Colors.white, size: 24)
                      : isDownloading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child:
                        Icon(Icons.download, color: Colors.white),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  isDownloading
                      ? 'Downloading...'
                      : isDownloaded
                      ? 'Downloaded!'
                      : 'Download PDF',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
