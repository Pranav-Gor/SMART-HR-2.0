import 'dart:async'; // Import for TimeoutException
import 'dart:convert';
import 'dart:io'; // Import for File and SocketException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for PlatformException
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Removed: import 'package:shared_preferences/shared_preferences.dart';

// --- Main Widget ---
class ProjectDetailScreen extends StatefulWidget {
  final String projectName;
  final String employeeId;
  final String
      projectid; // Keep as String for consistency with widget constructor
  final String employeeType;

  const ProjectDetailScreen({
    super.key,
    required this.projectName,
    required this.projectid,
    required this.employeeId,
    required this.employeeType,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

// --- State Class ---
class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // --- State Variables ---
  String firstname = "";
  String locationadd = ''; // Address string for display/debug

  // --- Future for Task Fetching ---
  Future<List<Map<String, dynamic>>>? _tasksFuture;

  // --- Task-Specific Location Storage (Using Widget State) ---
  // Stores geocoded destination positions (fetched during START or ARRIVAL check)
  final Map<String, Position?> taskDestinations = {};
  // Stores user's start positions captured when 'Start' is pressed
  final Map<String, Position?> userStartPositions = {};
  // Stores the start coordinate string fetched from checkarrivaldistance.php to be sent to arrivedtask.php
  final Map<String, String?> taskStartCoordsStr = {};

  // State Maps for Task Tracking
  final Map<String, XFile?> _taskTicketImages = {}; // Make XFile nullable
  final Map<String, bool> taskCompletedStatus = {};
  final Map<String, bool> taskStartedStatus = {};
  final Map<String, bool> taskArrivedStatus = {};
  final Map<String, double?> taskArrivalDistancesKM =
      {}; // For display if calculated (Now ONLY set by Distance Matrix API)

  // --- Configuration ---
  // Using the provided Distance Matrix API Key
  final String distancematrixApiKey =
      '9mEl8a8mP0RKiw6uRkwXoHQPayCjFJb6D01iAJFpdHmRPykJ8JazuInXqzOYWFQx'; // <<< Using provided key
  final Color primaryColor = const Color(0xffeef444c);
  // Using the provided API Base URL
  final String baseApiUrl =
      'http://192.168.29.211/hr_api'; // <--- Using provided URL
  final double arrivalThresholdMeters =
      500.0; // <<< Threshold to compare API distance against

  // --- Lifecycle & Initial Setup ---
  @override
  void initState() {
    super.initState();
    print("ProjectDetailScreen initState called");
    _checkAndRequestPermissions();
    fetchEmployeeData();
    _tasksFuture = fetchTasks(); // Initialize the tasks future
    print("Initial _tasksFuture set in initState");
  }

  // --- Helper Functions (Permissions, Snackbars, Loading Dialogs) ---

  Future<bool> _checkAndRequestPermissions() async {
    // ... (Permission checking logic remains the same)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      if (mounted)
        _showErrorSnackBar(
            'Location services are disabled. Please enable them.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        if (mounted)
          _showErrorSnackBar(
              'Location permissions are denied. Cannot perform location actions.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      if (mounted)
        _showErrorSnackBar(
            'Location permissions are permanently denied. Please enable them in app settings.');
      return false;
    }

    print("Location permissions granted.");
    return true;
  }

  void _showErrorSnackBar(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    // ... (Snackbar logic remains the same)
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else {
      print("Error SnackBar not shown: ScaffoldMessenger not found.");
    }
  }

  void _showSuccessSnackBar(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    // ... (Snackbar logic remains the same)
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else {
      print("Success SnackBar not shown: ScaffoldMessenger not found.");
    }
  }

  // MODIFIED _showLoadingDialog to prevent overflow
  void _showLoadingDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min, // Important to keep dialog compact
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 25),
                Flexible(
                  // <-- Wrap Text with Flexible
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    // ... (Loading dialog logic remains the same)
    if (!mounted) return;
    // Added check to prevent popping if no dialog is active
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        // Might happen if dialog was already closed by another async operation
        print("Hide loading dialog error (ignorable): $e");
      }
    }
  }

  // --- Data Fetching ---
  Future<void> fetchEmployeeData() async {
    // ... (Employee data fetching remains the same)
    print("Fetching employee data...");
    try {
      final response = await http
          .get(Uri.parse('$baseApiUrl/showemp.php'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> employeeList = jsonDecode(response.body);
        final employeeData = employeeList.firstWhere(
          (employee) => employee['userID']?.toString() == widget.employeeId,
          orElse: () => null,
        );
        if (employeeData != null && mounted) {
          setState(() {
            firstname = employeeData['firstName'] ?? 'N/A';
            print("Employee data loaded: $firstname");
          });
        } else {
          print("Employee data not found for ID: ${widget.employeeId}");
        }
      } else {
        print(
            "Failed to fetch employee data. Status code: ${response.statusCode}");
        if (mounted)
          _showErrorSnackBar(
              'Failed to load employee details (${response.statusCode}).');
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      print("Timeout fetching employee data.");
      if (mounted)
        _showErrorSnackBar(
            'Failed to load employee details: Connection timed out.');
    } on SocketException catch (e) {
      if (!mounted) return;
      print("Network error fetching employee data: $e");
      if (mounted)
        _showErrorSnackBar('Network error loading employee details.');
    } catch (e) {
      if (!mounted) return;
      print("Error fetching employee data: $e");
      if (mounted) _showErrorSnackBar('Error loading employee details.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    // ... (Task fetching and state map initialization remains mostly the same)
    print(
        "Fetching tasks for Employee ID: ${widget.employeeId}, Project ID: ${widget.projectid}");
    try {
      final response = await http
          .get(Uri.parse('$baseApiUrl/showtask.php'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return [];

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          final List<dynamic> tasks = responseData;
          print("Fetched ${tasks.length} total tasks from API.");
          final filteredTasks = tasks.where((task) {
            final taskUserId = task['userID']?.toString();
            final taskProjectId = task['projectID']?.toString();
            return taskUserId == widget.employeeId &&
                taskProjectId == widget.projectid;
          }).toList();

          print(
              "Filtered down to ${filteredTasks.length} tasks for this project/employee.");

          bool needsStateUpdate = false;
          Set<String> currentTaskIds = {};

          for (var task in filteredTasks) {
            final taskId = task['taskID']?.toString();
            if (taskId != null) {
              currentTaskIds.add(taskId);
              final status =
                  task['status']?.toString().toLowerCase() ?? 'pending';
              bool isApiCompleted = (status == "completed");
              bool isApiArrived = (status == "arrived" || isApiCompleted);
              bool isApiStarted =
                  (status == "start_in" || isApiArrived || isApiCompleted);

              // Update local maps based on API status
              if (taskCompletedStatus[taskId] != isApiCompleted) {
                taskCompletedStatus[taskId] = isApiCompleted;
                needsStateUpdate = true;
              } else {
                taskCompletedStatus.putIfAbsent(taskId, () {
                  needsStateUpdate = true;
                  return isApiCompleted;
                });
              }
              if (taskStartedStatus[taskId] != isApiStarted) {
                taskStartedStatus[taskId] = isApiStarted;
                needsStateUpdate = true;
              } else {
                taskStartedStatus.putIfAbsent(taskId, () {
                  needsStateUpdate = true;
                  return isApiStarted;
                });
              }
              if (taskArrivedStatus[taskId] != isApiArrived) {
                taskArrivedStatus[taskId] = isApiArrived;
                needsStateUpdate = true;
              } else {
                taskArrivedStatus.putIfAbsent(taskId, () {
                  needsStateUpdate = true;
                  return isApiArrived;
                });
              }

              // Initialize other maps if needed
              taskArrivalDistancesKM.putIfAbsent(taskId, () => null);
              _taskTicketImages.putIfAbsent(taskId, () => null);
            } else {
              print("Warning: Task found with null taskID in API response.");
            }
          }

          // Clean up state maps for obsolete tasks
          List<String> keysToRemove = taskCompletedStatus.keys
              .where((key) => !currentTaskIds.contains(key))
              .toList();
          if (keysToRemove.isNotEmpty) {
            print("Removing state for obsolete task IDs: $keysToRemove");
            for (String key in keysToRemove) {
              taskCompletedStatus.remove(key);
              taskStartedStatus.remove(key);
              taskArrivedStatus.remove(key);
              taskArrivalDistancesKM.remove(key);
              taskDestinations.remove(key);
              userStartPositions.remove(key);
              _taskTicketImages.remove(key);
              taskStartCoordsStr.remove(key);
            }
            needsStateUpdate = true;
          }

          if (needsStateUpdate && mounted) {
            print(
                "Triggering setState after fetchTasks because local state maps were updated.");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }

          return filteredTasks.cast<Map<String, dynamic>>();
        } else {
          print('Unexpected response format from tasks API: $responseData');
          if (mounted) _showErrorSnackBar('Invalid data format from server.');
          return [];
        }
      } else {
        print('Failed to load tasks. Status code: ${response.statusCode}');
        if (mounted)
          _showErrorSnackBar('Failed to load tasks (${response.statusCode})');
        return [];
      }
    } on TimeoutException catch (_) {
      if (mounted)
        _showErrorSnackBar('Failed to load tasks: Connection timed out.');
      return [];
    } on SocketException catch (e) {
      print("Network error fetching tasks: $e");
      if (mounted)
        _showErrorSnackBar('Network error. Please check connection.');
      return [];
    } on FormatException catch (e) {
      print("Error parsing task data: $e");
      if (mounted)
        _showErrorSnackBar('Error processing task data from server.');
      return [];
    } catch (e) {
      print("Error fetching tasks: $e");
      if (mounted)
        _showErrorSnackBar('An unknown error occurred while loading tasks.');
      return [];
    }
  }

  // Helper to create a placeholder Position object
  Position _createPlaceholderPosition() {
    return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0);
  }

  // Helper to parse "lat,lng" string to Position object
  Position? _parseCoordsToPosition(String? coords, {DateTime? timestamp}) {
    if (coords == null || !coords.contains(',')) return null;
    final parts = coords.split(',');
    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) return null;

    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) {
      print(
          "Parsed coordinates are (0,0) or very close. Treating as potentially invalid.");
    }

    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  // --- UI Widgets (Build, Task Card, Info Item, Ticket Preview) ---

  @override
  Widget build(BuildContext context) {
    print("ProjectDetailScreen build method running...");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(
              fontFamily: 'NexaBold', color: Colors.white, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          print("Refresh triggered");
          await fetchEmployeeData();
          if (mounted) {
            setState(() {
              print("Setting new _tasksFuture in onRefresh");
              _tasksFuture = fetchTasks();
            });
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Project Header Card ---
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/prodetails.jpg',
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: 150,
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.broken_image_outlined,
                              size: 50, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Assigned to: ${firstname.isNotEmpty ? firstname : "Loading..."}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Your Tasks',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.black26),
              const SizedBox(height: 16),

              // --- Task List (Using FutureBuilder) ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  print(
                      "FutureBuilder rebuilding. Connection State: ${snapshot.connectionState}");

                  // 1. Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator()));
                  }

                  // 2. Error State
                  if (snapshot.hasError) {
                    print("FutureBuilder Error: ${snapshot.error}");
                    print("FutureBuilder StackTrace: ${snapshot.stackTrace}");
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 40),
                                const SizedBox(height: 10),
                                Text('Error loading tasks: ${snapshot.error}',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Retry"),
                                  onPressed: () {
                                    if (mounted) {
                                      setState(() {
                                        print(
                                            "Retry button pressed, setting new _tasksFuture");
                                        _tasksFuture = fetchTasks();
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            )));
                  }

                  // 3. No Data State
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    print(
                        "FutureBuilder: Done, but no data or empty data received.");
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'No tasks assigned for this project\nor check your connection.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // 4. Data Available State
                  final List<Map<String, dynamic>> allTasks = snapshot.data!;
                  print(
                      "FutureBuilder: Received ${allTasks.length} tasks from Future.");

                  // Filter tasks based on LOCAL completed status map
                  final List<Map<String, dynamic>> visibleTasks =
                      allTasks.where((task) {
                    final taskId = task['taskID']?.toString();
                    if (taskId == null) return false;
                    bool isLocallyCompleted =
                        taskCompletedStatus[taskId] ?? false;
                    return !isLocallyCompleted;
                  }).toList();
                  print(
                      "FutureBuilder: Filtered down to ${visibleTasks.length} visible tasks based on local state.");

                  if (visibleTasks.isEmpty) {
                    print(
                        "FutureBuilder: No visible tasks to display (all might be completed or fetch error).");
                    String message = allTasks.isNotEmpty
                        ? 'All assigned tasks are completed!'
                        : 'No tasks were found for this project.';
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(message,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ));
                  }

                  // Build the list
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      final taskId =
                          task['taskID']?.toString() ?? 'error_id_$index';
                      // Get status flags from LOCAL state maps
                      final bool isStarted = taskStartedStatus[taskId] ?? false;
                      final bool isArrived = taskArrivedStatus[taskId] ?? false;
                      return _buildTaskCard(task, isStarted, isArrived, false);
                    },
                  );
                },
              ),
              const SizedBox(height: 20), // Footer padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isTaskStarted,
      bool isTaskArrived, bool isTaskCompleted) {
    // ... (Task card structure remains largely the same)
    final taskId = task['taskID']?.toString() ?? 'unknown_task';
    final transport = task['transport'] as String? ?? '';
    final isBusTrain = transport.toLowerCase().contains('bus') ||
        transport.toLowerCase().contains('train');
    final ticketFile = _taskTicketImages[taskId];
    final hasTicket = ticketFile != null && ticketFile.path.isNotEmpty;
    final taskAddress = task['address'] as String? ?? 'No Address Provided';
    final taskDescription = task['task'] as String? ?? 'No Description';
    final module = task['module'] as String? ?? 'Task';
    final deadlineString = task['deadline'] as String? ?? '';

    String formattedDeadline = 'N/A';
    if (deadlineString.isNotEmpty) {
      try {
        final deadlineDate =
            DateTime.parse(deadlineString.replaceFirst(' ', 'T'));
        formattedDeadline =
            DateFormat('dd MMM yyyy, hh:mm a').format(deadlineDate);
      } catch (e) {
        print("Error parsing deadline '$deadlineString': $e");
        formattedDeadline = deadlineString;
      }
    }

    Color statusColor;
    String displayStatus;
    if (isTaskCompleted) {
      statusColor = Colors.green;
      displayStatus = "Completed";
    } else if (isTaskArrived) {
      statusColor = Colors.blue;
      displayStatus = "Arrived";
    } else if (isTaskStarted) {
      statusColor = Colors.orange;
      displayStatus = "Started";
    } else {
      statusColor = Colors.grey;
      displayStatus = "Pending";
    }

    // Display distance if available
    final distanceKm = taskArrivalDistancesKM[taskId];
    String distanceText = '';
    if (distanceKm != null) {
      if (distanceKm * 1000 < 1000) {
        distanceText = "${(distanceKm * 1000).toStringAsFixed(0)} m away";
      } else {
        distanceText = "${distanceKm.toStringAsFixed(1)} km away";
      }
    }

    return Container(
      key: ValueKey(taskId),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show ticket only if applicable and uploaded
            if (isBusTrain && hasTicket) ...[
              _buildTicketPreview(taskId),
              const SizedBox(height: 16),
            ],

            Row(
              /* ... Header row with status ... */
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(module,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(displayStatus,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(taskDescription,
                style: const TextStyle(
                    fontSize: 15, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 14),

            // Address (if onfield)
            if (widget.employeeType == 'onfield' &&
                taskAddress != 'No Address Provided') ...[
              Row(
                /* ... Address row ... */
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(taskAddress,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 118, 118, 118)))),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Deadline & Distance Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    // Wrap deadline info to prevent overflow if address is long
                    child: _buildInfoItem(
                        Icons.calendar_today_outlined, formattedDeadline)),
                if (distanceText.isNotEmpty) // Show distance if available
                  Padding(
                    // Add padding if distance is shown
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildInfoItem(Icons.route_outlined, distanceText),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildActionButtons(task, isTaskStarted, isTaskArrived,
                  taskCompletedStatus[taskId] ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPreview(String taskId) {
    // ... (Ticket preview logic remains the same)
    final ticketImage = _taskTicketImages[taskId];
    if (ticketImage == null || ticketImage.path.isEmpty)
      return const SizedBox.shrink();
    final imageFile = File(ticketImage.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Uploaded Ticket:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7.0),
                child: FutureBuilder<bool>(
                    future: imageFile.exists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.0));
                      }
                      if (snapshot.hasError || snapshot.data == false) {
                        print(
                            "Error checking/finding ticket file: ${ticketImage.path} Error: ${snapshot.error}");
                        return Center(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[300], size: 30),
                            const SizedBox(height: 5),
                            Text(
                              "Ticket file missing.\nPlease re-upload.",
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ));
                      }
                      return Image.file(
                        imageFile,
                        fit: BoxFit.contain,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (frame == null)
                            return const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.0));
                          return child;
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              "Error loading ticket image file ${ticketImage.path}: $error");
                          return const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.grey, size: 40));
                        },
                      );
                    }),
              ),
            ),
            // Conditionally show remove button only if task not started
            if (!(taskStartedStatus[taskId] ?? false))
              InkWell(
                onTap: () {
                  if (taskStartedStatus[taskId] ?? false) {
                    _showErrorSnackBar(
                        "Cannot remove ticket after task has started.");
                    return;
                  }
                  if (mounted) {
                    setState(() => _taskTicketImages[taskId] = null);
                    print("Ticket image removed for task $taskId");
                    _showSuccessSnackBar("Ticket image removed.");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    // ... (Info item widget remains the same)
    text = text.isEmpty ? 'N/A' : text;
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Keep this to allow side-by-side placement
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Flexible(
          // Allow text to wrap/ellipsis if needed within its available space
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14, color: Color.fromARGB(255, 119, 119, 119)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> task,
      bool isTaskStarted, bool isTaskArrived, bool isTaskCompleted) {
    // ... (Action button logic remains the same)
    String taskId = task['taskID']?.toString() ?? 'error_id';
    String taskAddress = task['address'] as String? ?? '';
    List<Widget> buttons = [];

    bool startButtonEnabled =
        !isTaskStarted && !isTaskArrived && !isTaskCompleted;
    bool arrivedButtonEnabled = isTaskStarted &&
        !isTaskArrived &&
        !isTaskCompleted &&
        widget.employeeType == 'onfield';
    bool completeButtonEnabled = isTaskStarted &&
        !isTaskCompleted &&
        (widget.employeeType == 'office' || isTaskArrived);

    Widget buildButton(String text, VoidCallback? onPressed, Color color,
        [IconData? icon]) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ElevatedButton.icon(
            icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
            label: Text(text,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    onPressed != null ? color : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                elevation: onPressed != null ? 2 : 0,
                textStyle: const TextStyle(letterSpacing: 0.4)),
          ),
        ),
      );
    }

    VoidCallback? startAction = startButtonEnabled
        ? () async {
            print("Start button pressed for task $taskId");
            bool hasPermission = await _checkAndRequestPermissions();
            if (!hasPermission) return;
            _showTransportDialog(taskId, taskAddress);
          }
        : null;

    VoidCallback? arrivedAction = arrivedButtonEnabled
        ? () async {
            print("Arrived pressed for task $taskId");
            await _markAsArrived(
                taskId); // Uses Distance Matrix exclusively now
          }
        : null;

    VoidCallback? completeAction = completeButtonEnabled
        ? () async {
            await _markAsCompleted(taskId);
          }
        : null;

    buttons.add(buildButton(
        'Start', startAction, primaryColor, Icons.play_arrow_outlined));
    if (widget.employeeType == 'onfield') {
      buttons.add(buildButton(
          'Arrived', arrivedAction, Colors.blue, Icons.location_pin));
    }
    buttons.add(buildButton(
        'Complete', completeAction, Colors.green, Icons.check_circle_outline));

    return buttons;
  }

  // --- Dialogs (Transport, Fuel, Ticket Upload) ---

  Future<void> _showTransportDialog(String taskId, String taskAddress) async {
    // ... (Transport dialog logic remains the same)
    String? selectedTransport = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? transport;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Transportation',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildHorizontalTransportOption(
                            transport,
                            'Bike',
                            'assets/images/bicycle.png',
                            setStateDialog,
                            (value) => transport = value),
                        _buildHorizontalTransportOption(
                            transport,
                            'Car',
                            'assets/images/car.png',
                            setStateDialog,
                            (value) => transport = value),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: transport != null
                              ? () => Navigator.pop(context, transport)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Text('Confirm'),
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

    if (selectedTransport == null) return;
    print("Transport selected: $selectedTransport");

    try {
      if (selectedTransport == 'Car') {
        await _showCarFuelTypeDialog(taskId, taskAddress);
      } else if (selectedTransport == 'Bus/Train') {
        await _showTicketUploadDialog(taskId, taskAddress);
      } else {
        _showLoadingDialog("Starting Task...");
        await _startTaskWithLocation(taskId, taskAddress, selectedTransport);
        _hideLoadingDialog(); // Ensure hidden after successful start
      }
    } catch (e) {
      print("Error after transport selection dialog: $e");
      if (mounted) _hideLoadingDialog(); // Ensure hidden on error
      if (mounted) _showErrorSnackBar("An error occurred: ${e.toString()}");
    }
  }

  Widget _buildHorizontalTransportOption(
    String? groupValue,
    String value,
    String imagePath,
    StateSetter setState,
    Function(String?) onChanged,
  ) {
    bool isSelected = groupValue == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          onChanged(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error_outline, size: 50, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCarFuelTypeDialog(String taskId, String taskAddress) async {
    // ... (Fuel dialog logic remains the same)
    String? fuelType = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String? selectedFuel;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Fuel Type',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildHorizontalOption(
                            selectedFuel,
                            'Petrol',
                            'assets/images/gas.png',
                            setStateDialog,
                            (value) => selectedFuel = value),
                        _buildHorizontalOption(
                            selectedFuel,
                            'Diesel',
                            'assets/images/gas.png',
                            setStateDialog,
                            (value) => selectedFuel = value),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: selectedFuel != null
                              ? () => Navigator.pop(context, selectedFuel)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Text('Confirm'),
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

    if (fuelType == null) return;
    print("Fuel type selected: $fuelType");
    _showLoadingDialog("Starting Task...");
    try {
      await _startTaskWithLocation(taskId, taskAddress, 'Car ($fuelType)');
    } finally {
      if (mounted) _hideLoadingDialog(); // Ensure hidden regardless of outcome
    }
  }

  Widget _buildHorizontalOption(
    String? groupValue,
    String value,
    String imagePath,
    StateSetter setState,
    Function(String?) onChanged,
  ) {
    bool isSelected = groupValue == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          onChanged(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTicketUploadDialog(
      String taskId, String taskAddress) async {
    // ... (Ticket upload/replace logic remains the same)
    final currentTicket = _taskTicketImages[taskId];
    final bool hasExistingTicket =
        currentTicket != null && currentTicket.path.isNotEmpty;
    bool proceedToUpload = false;

    if (hasExistingTicket) {
      bool? replace = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Ticket Already Uploaded"),
          content: const Text(
              "A ticket image is already associated with this task.\nDo you want to replace it or use the existing one?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Use Existing")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Replace"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white)),
          ],
        ),
      );
      if (replace == null) return;
      if (!replace) {
        print("Proceeding with existing ticket for task $taskId.");
        _showLoadingDialog("Starting Task...");
        try {
          await _startTaskWithLocation(taskId, taskAddress, 'Bus/Train');
        } finally {
          if (mounted) _hideLoadingDialog();
        }
        return;
      } else {
        proceedToUpload = true;
      }
    } else {
      bool? confirmUpload = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Upload Ticket Required'),
            content: const Text(
                'For Bus/Train travel, please upload a photo of your ticket to start the task.'),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding:
                const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white),
                child: const Text('Upload Ticket'),
              ),
            ],
          );
        },
      );
      if (confirmUpload != true) {
        if (mounted)
          _showErrorSnackBar("Ticket upload cancelled. Task not started.");
        return;
      } else {
        proceedToUpload = true;
      }
    }

    if (proceedToUpload) {
      if (!mounted) return;
      _showLoadingDialog("Opening Image Picker...");
      XFile? pickedFile;
      try {
        pickedFile = await ImagePicker()
            .pickImage(source: ImageSource.gallery, imageQuality: 70);
      } on PlatformException catch (e) {
        print("Error picking image (PlatformException): $e");
        if (mounted) {
          _hideLoadingDialog();
          _showErrorSnackBar(
              "Could not access photos: ${e.message ?? 'Permission denied'}");
        }
        return;
      } catch (e) {
        print("Error picking image (General): $e");
        if (mounted) {
          _hideLoadingDialog();
          _showErrorSnackBar("An error occurred while picking the image.");
        }
        return;
      } finally {
        // Hide loading only if picker cancelled, otherwise handled below
        if (mounted && pickedFile == null) _hideLoadingDialog();
      }

      if (pickedFile != null) {
        if (!mounted) return;
        print("Ticket image selected: ${pickedFile.path}");
        setState(() => _taskTicketImages[taskId] = pickedFile);
        _hideLoadingDialog(); // Hide image picker loading
        _showSuccessSnackBar('Ticket photo selected.');

        _showLoadingDialog("Starting Task...");
        try {
          await _startTaskWithLocation(taskId, taskAddress, 'Bus/Train');
        } finally {
          if (mounted) _hideLoadingDialog(); // Hide start task loading
        }
      } else {
        print("No image selected from picker.");
        if (mounted) {
          // No need to hide loading dialog here if picker was cancelled, already handled in finally
          if (!hasExistingTicket) {
            _showErrorSnackBar("No image selected. Task not started.");
          } else {
            // If replacing, but cancelled picker, start with existing ticket
            _showSuccessSnackBar(
                "Ticket replacement cancelled. Using original ticket.");
            _showLoadingDialog("Starting Task with original ticket...");
            try {
              await _startTaskWithLocation(taskId, taskAddress, 'Bus/Train');
            } finally {
              if (mounted) _hideLoadingDialog();
            }
          }
        }
      }
    }
  }

  // --- Core Task Actions ---

  // 1. Geocode Address (Still useful for Start/Display)
  Future<Position?> _fetchTaskDestination(String taskId, String address) async {
    // ... (Geocoding logic remains the same)
    if (!mounted) return null;
    const String noAddressPlaceholder = 'No Address Provided';
    taskDestinations.remove(taskId);

    if (address.isEmpty ||
        address == noAddressPlaceholder ||
        address.trim().length < 3) {
      print(
          "Geocoding Skipped: Task address empty/invalid for task $taskId: '$address'");
      return null;
    }

    print("Attempting to geocode address: '$address' for task $taskId");
    try {
      List<Location> locations = await locationFromAddress(address)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return null;

      if (locations.isNotEmpty) {
        final location = locations.first;
        if (location.latitude.abs() < 0.0001 &&
            location.longitude.abs() < 0.0001) {
          print(
              "Geocoding WARNING for task $taskId: Result is near (0,0). Treating as invalid.");
          if (mounted)
            _showErrorSnackBar(
                "Could not determine a valid location for address: '$address'");
          return null;
        }
        final position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        print(
            'Geocoding SUCCESS for task $taskId: Lat ${position.latitude}, Lng ${position.longitude}');
        taskDestinations[taskId] = position;
        if (mounted) setState(() => locationadd = address);
        return position;
      } else {
        print("Geocoding FAILED for address: '$address'. No locations found.");
        if (mounted)
          _showErrorSnackBar(
              "Could not find location for the address: '$address'");
        return null;
      }
    } on TimeoutException catch (_) {
      print("Geocoding timeout for task $taskId address: $address");
      if (mounted) _showErrorSnackBar('Timeout finding location for address.');
      return null;
    } on SocketException catch (e) {
      print("Geocoding network error for task $taskId: $e");
      if (mounted)
        _showErrorSnackBar('Network error finding location. Check connection.');
      return null;
    } catch (e) {
      print("Geocoding error for task $taskId: $e");
      if (mounted)
        _showErrorSnackBar('Error finding location: ${e.toString()}');
      return null;
    }
  }

  // 2. Start Task: Get User Location, Fetch Dest (if needed), Call Start APIs & Update Local State
  Future<void> _startTaskWithLocation(
      String taskId, String taskAddress, String transport) async {
    // ... (Start task logic remains the same)
    if (!mounted) return;
    print("Attempting to start task $taskId with transport $transport");

    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) return;

    taskStartCoordsStr.remove(taskId);
    taskArrivalDistancesKM.remove(taskId);

    _showLoadingDialog("Getting Start Location...");
    Position? userCurrentPosition;
    try {
      userCurrentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 15))
          .timeout(const Duration(seconds: 15));
      if (mounted)
        print(
            "User start position captured (High Accuracy) for task $taskId: ${userCurrentPosition.latitude}, ${userCurrentPosition.longitude}");
    } on TimeoutException {
      print(
          "Timeout getting high accuracy location for task $taskId. Trying medium...");
      if (!mounted) {
        _hideLoadingDialog();
        return;
      }
      try {
        userCurrentPosition = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 10))
            .timeout(const Duration(seconds: 10));
        if (mounted)
          print(
              "User start position captured (Medium Accuracy) for task $taskId: ${userCurrentPosition?.latitude}, ${userCurrentPosition?.longitude}");
      } catch (e) {
        print(
            "Error getting medium accuracy location for task $taskId: $e. Trying last known.");
      }
    } catch (e) {
      print(
          "Error getting current location for task $taskId: $e. Trying last known.");
    }

    if (userCurrentPosition == null && mounted) {
      try {
        userCurrentPosition = await Geolocator.getLastKnownPosition();
        if (userCurrentPosition != null && mounted) {
          print(
              "Using last known position for task $taskId: ${userCurrentPosition.latitude}, ${userCurrentPosition.longitude}");
          if (mounted)
            _showSuccessSnackBar("Using last known location due to GPS issues.",
                duration: const Duration(seconds: 5));
        } else {
          print(
              "No current or last known position available for task $taskId.");
          if (mounted)
            _showErrorSnackBar(
                "Couldn't get start location. Task will start without precise coordinates.");
        }
      } catch (fallbackError) {
        print(
            "Error getting last known location for task $taskId: $fallbackError");
      }
    }

    if (mounted) {
      userStartPositions[taskId] = userCurrentPosition;
      _hideLoadingDialog();
    } else {
      return;
    }

    Position? destinationPos;
    if (widget.employeeType == 'onfield') {
      _showLoadingDialog("Getting Task Destination...");
      destinationPos = await _fetchTaskDestination(taskId, taskAddress);
      if (!mounted) return;
      _hideLoadingDialog();
      if (destinationPos == null) {
        print(
            "Start Task Warning [Onfield]: Could not geocode destination address for task $taskId.");
      } else {
        print(
            "Start Task [Onfield]: Destination geocoded: ${destinationPos.latitude}, ${destinationPos.longitude}");
      }
    }

    _showLoadingDialog("Starting Task...");
    String startDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var startUrl = Uri.parse('$baseApiUrl/starttask.php');
    bool startLogSuccess = false;
    bool transportUpdateSuccess = false;

    try {
      final startResponse = await http
          .post(
            startUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode({'taskID': taskId, 'startDate': startDate}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        _hideLoadingDialog();
        return;
      }

      print(
          "API Response (Start Log) [$taskId]: ${startResponse.statusCode} ${startResponse.body}");
      if (startResponse.statusCode == 200) {
        try {
          final responseBody = json.decode(startResponse.body);
          if (responseBody is Map && responseBody['success'] == true) {
            startLogSuccess = true;
          } else {
            if (mounted)
              _showErrorSnackBar(
                  responseBody['message'] ?? 'Failed to log task start.');
          }
        } catch (e) {
          print("Error parsing start log response: $e");
          if (mounted)
            _showErrorSnackBar('Invalid response from start task server.');
        }
      } else {
        if (mounted)
          _showErrorSnackBar(
              'Failed to log task start (Server Error ${startResponse.statusCode}).');
      }

      if (startLogSuccess && mounted) {
        transportUpdateSuccess = await _updateTransportationMethod(
            taskId, transport, userCurrentPosition, destinationPos);
      }

      if (startLogSuccess && mounted) {
        setState(() {
          taskStartedStatus[taskId] = true;
          taskArrivedStatus[taskId] = false;
          taskCompletedStatus[taskId] = false;
          taskArrivalDistancesKM.remove(taskId);
        });
        if (transportUpdateSuccess) {
          if (mounted) _showSuccessSnackBar('Task started with $transport!');
        } else {
          if (mounted)
            _showErrorSnackBar(
                'Task started, but failed to save transport method.');
        }
      } else if (mounted) {
        print("Task start aborted for $taskId due to API failure (start log).");
        userStartPositions.remove(taskId);
        taskDestinations.remove(taskId);
      }
    } on TimeoutException catch (_) {
      if (mounted) _showErrorSnackBar('Request timed out while starting task.');
      userStartPositions.remove(taskId);
      taskDestinations.remove(taskId);
    } on SocketException catch (_) {
      if (mounted)
        _showErrorSnackBar('Network error. Please check connection.');
      userStartPositions.remove(taskId);
      taskDestinations.remove(taskId);
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error starting task: ${e.toString()}');
      userStartPositions.remove(taskId);
      taskDestinations.remove(taskId);
    } finally {
      if (mounted) _hideLoadingDialog();
    }
  }

  // 3. Get Route Distance (Distance Matrix API) - Used EXCLUSIVELY in Arrival Check
  Future<Map<String, dynamic>> _getRouteInfoFromDistanceMatrix(String taskId,
      Position userPosition, Position destinationPosition) async {
    // ... (Function remains the same as previous version)
    if (!mounted) return {'success': false, 'message': 'Operation cancelled.'};
    print("_getRouteInfoFromDistanceMatrix: Called for task $taskId");

    // Check for API Key
    if (distancematrixApiKey == '' ||
        distancematrixApiKey.isEmpty ||
        distancematrixApiKey.length < 10) {
      // Added basic length check
      print("--- DISTANCE MATRIX API KEY MISSING OR INVALID ---");
      return {
        'success': false,
        'message': 'Distance Matrix API key not configured.'
      };
    }

    // Check for potentially invalid coordinates
    if (destinationPosition.latitude.abs() < 0.0001 &&
            destinationPosition.longitude.abs() < 0.0001 ||
        userPosition.latitude.abs() < 0.0001 &&
            userPosition.longitude.abs() < 0.0001) {
      print(
          "_getRouteInfoFromDistanceMatrix: Invalid coordinates provided. User:(${userPosition.latitude},${userPosition.longitude}), Dest:(${destinationPosition.latitude},${destinationPosition.longitude})");
      return {
        'success': false,
        'message': 'Invalid start or destination coordinates.'
      };
    }

    final String apiUrl =
        'https://api.distancematrix.ai/maps/api/distancematrix/json'
        '?origins=${userPosition.latitude},${userPosition.longitude}'
        '&destinations=${destinationPosition.latitude},${destinationPosition.longitude}'
        '&key=$distancematrixApiKey';

    print(
        '_getRouteInfoFromDistanceMatrix [Task $taskId]: Calling API: $apiUrl');
    Map<String, dynamic> result = {
      'success': false,
      'message': 'Failed to get route details.'
    };

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 20));
      if (!mounted)
        return {'success': false, 'message': 'Operation cancelled.'};

      print(
          '--- Distance API Response [Task $taskId] (${response.statusCode}) ---\n${response.body}\n--------------');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'OK' &&
            responseData['rows'] is List &&
            responseData['rows'].isNotEmpty &&
            responseData['rows'][0]['elements'] is List &&
            responseData['rows'][0]['elements'].isNotEmpty) {
          final element = responseData['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            int? distanceMeters = element['distance']?['value'] as int?;
            int? durationSeconds = element['duration']?['value'] as int?;

            if (distanceMeters != null) {
              double distanceKm = distanceMeters / 1000.0;
              print(
                  '_getRouteInfoFromDistanceMatrix [Task $taskId]: Parsed distance: $distanceMeters meters (${distanceKm.toStringAsFixed(3)} km)');

              // Update state map for display using WidgetsBinding
              if (mounted && taskArrivalDistancesKM[taskId] != distanceKm) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => taskArrivalDistancesKM[taskId] = distanceKm);
                  }
                });
              }
              result = {
                'success': true,
                'distance_meters': distanceMeters,
                'distance_km': distanceKm,
                'duration_seconds': durationSeconds,
                'message': 'Route details fetched successfully.'
              };
            } else {
              result['message'] = 'Distance data not found in API response.';
              print(
                  '_getRouteInfoFromDistanceMatrix Error [Task $taskId]: ${result['message']}');
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted)
                    setState(() => taskArrivalDistancesKM[taskId] = null);
                });
              }
            }
          } else {
            result['message'] =
                'API element status not OK: ${element['status']}';
            print(
                '_getRouteInfoFromDistanceMatrix Error [Task $taskId]: ${result['message']}');
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  setState(() => taskArrivalDistancesKM[taskId] = null);
              });
            }
          }
        } else {
          result['message'] =
              'API status not OK or invalid structure: ${responseData['status']}';
          print(
              '_getRouteInfoFromDistanceMatrix Error [Task $taskId]: ${result['message']}');
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                setState(() => taskArrivalDistancesKM[taskId] = null);
            });
          }
        }
      } else {
        result['message'] =
            'Distance API request failed (${response.statusCode}).';
        print(
            '_getRouteInfoFromDistanceMatrix Error [Task $taskId]: ${result['message']}');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => taskArrivalDistancesKM[taskId] = null);
          });
        }
      }
    } on TimeoutException catch (_) {
      print("_getRouteInfoFromDistanceMatrix [Task $taskId]: Timeout error.");
      result['message'] = 'Timeout getting route details.';
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => taskArrivalDistancesKM[taskId] = null);
        });
      }
    } on SocketException catch (e) {
      print(
          "_getRouteInfoFromDistanceMatrix [Task $taskId]: Network error: $e");
      result['message'] = 'Network error. Check connection.';
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => taskArrivalDistancesKM[taskId] = null);
        });
      }
    } catch (e) {
      print("_getRouteInfoFromDistanceMatrix [Task $taskId]: Error: $e");
      result['message'] = 'An error occurred fetching route details.';
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => taskArrivalDistancesKM[taskId] = null);
        });
      }
    }

    return result;
  }

  // 4. Mark Task as Arrived (Uses Distance Matrix API EXCLUSIVELY for distance check)
  Future<void> _markAsArrived(String taskid) async {
    // ... (Function flow remains the same as previous version, ensuring no Geolocator.distanceBetween is called)
    if (!mounted) return;
    print("_markAsArrived: Called for task $taskid");

    // --- Ensure Permissions & Get Current Location FIRST ---
    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) return;

    _showLoadingDialog("Getting Current Location...");
    Position? currentUserPosition;
    try {
      currentUserPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 15))
          .timeout(const Duration(seconds: 15));
      if (mounted)
        print(
            "_markAsArrived [Task $taskid]: Current User Location (High Acc): ${currentUserPosition.latitude}, ${currentUserPosition.longitude}");
    } catch (e) {
      print(
          "_markAsArrived [Task $taskid]: Error getting high accuracy location: $e. Trying medium/last known...");
      if (!mounted) {
        _hideLoadingDialog();
        return;
      }
      try {
        currentUserPosition = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 10))
            .timeout(const Duration(seconds: 10));
        if (mounted)
          print(
              "_markAsArrived [Task $taskid]: Current User Location (Med Acc): ${currentUserPosition?.latitude}, ${currentUserPosition?.longitude}");
      } catch (e2) {
        print(
            "_markAsArrived [Task $taskid]: Error getting medium accuracy location: $e2. Trying last known.");
        currentUserPosition = await Geolocator.getLastKnownPosition();
        if (currentUserPosition != null && mounted) {
          print(
              "_markAsArrived [Task $taskid]: Current User Location (Last Known): ${currentUserPosition.latitude}, ${currentUserPosition.longitude}");
        }
      }
    } finally {
      if (mounted)
        _hideLoadingDialog(); // Hide location dialog
      else
        return;
    }

    if (currentUserPosition == null) {
      if (mounted)
        _showErrorSnackBar(
            "Could not determine your current location to verify arrival.");
      return;
    }

    // --- Get Destination & Start Coords String from Backend ---
    _showLoadingDialog("Fetching Task Details...");
    Position? fetchedDestinationPosition;
    String? startCoordsStrForApi;
    String fetchMessage = "Error fetching task details.";
    bool fetchSuccess = false;
    int? taskIdInt = int.tryParse(taskid);

    if (taskIdInt == null) {
      if (mounted) _hideLoadingDialog();
      if (mounted) _showErrorSnackBar("Invalid task ID format: $taskid");
      return;
    }

    var checkUrl = Uri.parse('$baseApiUrl/checkarrivaldistance.php');
    print(
        '_markAsArrived [Task $taskid]: Calling Check Arrival API (for coords): $checkUrl');

    try {
      final checkResponse = await http
          .post(
            checkUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode({'taskID': taskIdInt}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) {
        _hideLoadingDialog();
        return;
      }

      print(
          '_markAsArrived [Task $taskid]: Check Arrival API Response (${checkResponse.statusCode}): ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        final responseBody = json.decode(checkResponse.body);
        String? startCoordsFromServer =
            responseBody['startLocation'] as String?;
        String? destCoordsStr = responseBody['destinationLocation'] as String?;

        startCoordsStrForApi = startCoordsFromServer;
        fetchedDestinationPosition = _parseCoordsToPosition(destCoordsStr);

        if (fetchedDestinationPosition != null &&
            startCoordsStrForApi != null) {
          print(
              "_markAsArrived [Task $taskid]: Destination coordinates fetched: ${fetchedDestinationPosition.latitude}, ${fetchedDestinationPosition.longitude}");
          print(
              "_markAsArrived [Task $taskid]: Start coordinates string fetched: $startCoordsStrForApi");
          taskDestinations[taskid] = fetchedDestinationPosition;
          taskStartCoordsStr[taskid] = startCoordsStrForApi;
          fetchSuccess = true;
        } else {
          fetchMessage = "Invalid location data received from server.";
          print(
              "_markAsArrived Error [$taskid]: Failed to parse coords. Dest: '$destCoordsStr', Start: '$startCoordsStrForApi'");
          fetchSuccess = false;
        }
      } else {
        fetchMessage =
            'Server error (${checkResponse.statusCode}) fetching task details.';
        print(
            "_markAsArrived Error [$taskid]: Check Arrival API HTTP Error: ${checkResponse.statusCode}");
        fetchSuccess = false;
      }
    } on TimeoutException catch (_) {
      print(
          "_markAsArrived Error [$taskid]: Timeout calling Check Arrival API.");
      fetchMessage = "Timeout fetching task details.";
      fetchSuccess = false;
    } on SocketException catch (_) {
      print(
          "_markAsArrived Error [$taskid]: Network error calling Check Arrival API.");
      fetchMessage = "Network error fetching task details.";
      fetchSuccess = false;
    } catch (e) {
      print(
          "_markAsArrived Error [$taskid]: Error calling Check Arrival API: $e");
      fetchMessage = "An unknown error occurred fetching task details.";
      fetchSuccess = false;
    } finally {
      if (mounted)
        _hideLoadingDialog(); // Hide fetch details dialog
      else
        return;
    }

    if (!fetchSuccess) {
      if (mounted) _showErrorSnackBar(fetchMessage);
      return;
    }

    // --- Calculate Distance using Distance Matrix API ---
    _showLoadingDialog("Calculating Route Distance...");
    bool canProceedToLog = false;
    String distanceMessage = "Error calculating distance.";

    // ** The core distance check using the API **
    Map<String, dynamic> routeInfo = await _getRouteInfoFromDistanceMatrix(
        taskid, currentUserPosition, fetchedDestinationPosition!);

    if (!mounted) {
      _hideLoadingDialog();
      return;
    } // Check mount after await

    _hideLoadingDialog(); // Hide distance calculation dialog

    if (routeInfo['success'] == true) {
      int distanceMeters = routeInfo['distance_meters'];
      distanceMessage = "Distance verified via API.";
      print(
          "_markAsArrived [Task $taskid]: Distance from API: $distanceMeters meters.");

      // Compare API distance against threshold
      if (distanceMeters <= arrivalThresholdMeters) {
        print(
            "_markAsArrived [Task $taskid]: User is WITHIN threshold ($arrivalThresholdMeters m) based on API distance.");
        canProceedToLog = true;
      } else {
        print(
            "_markAsArrived [Task $taskid]: User is OUTSIDE threshold ($arrivalThresholdMeters m) based on API distance.");
        distanceMessage =
            "You are not close enough to the destination (approx. ${distanceMeters.toStringAsFixed(0)}m away based on route).";
        canProceedToLog = false;
        if (mounted) {
          _showErrorSnackBar(distanceMessage); // Show immediate feedback
          // UI update for distance display is handled within _getRouteInfoFromDistanceMatrix
        }
      }
    } else {
      // Distance calculation failed
      distanceMessage = routeInfo['message'] ?? 'Failed to verify distance.';
      print(
          "_markAsArrived Error [$taskid]: Distance Matrix API failed: $distanceMessage");
      canProceedToLog = false;
      if (mounted) _showErrorSnackBar(distanceMessage);
    }

    // --- If Distance Check Passed, Log Arrival Time ---
    if (!canProceedToLog) {
      print("_markAsArrived [Task $taskid]: Cannot proceed to log arrival.");
      return;
    }

    print(
        "_markAsArrived [Task $taskid]: Distance check successful. Proceeding to log arrival time.");
    _showLoadingDialog("Marking as Arrived...");

    String arrivalTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var logUrl = Uri.parse('$baseApiUrl/arrivedtask.php');
    bool logSuccess = false;
    String logMessage = "Error logging arrival time.";

    try {
      var logResponse = await http
          .post(
            logUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'taskID': taskid,
              'arrivalTime': arrivalTime,
              'startCoordsStr': startCoordsStrForApi ?? ""
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        _hideLoadingDialog();
        return;
      }

      print(
          '_markAsArrived [Task $taskid]: Log Arrival API Response (${logResponse.statusCode}): ${logResponse.body}');

      if (logResponse.statusCode == 200) {
        try {
          final responseBody = json.decode(logResponse.body);
          if (responseBody is Map && responseBody['success'] == true) {
            logSuccess = true;
            logMessage = responseBody['message'] ?? "Task marked as Arrived!";
          } else {
            logMessage =
                responseBody['message'] ?? 'Failed to log arrival status.';
          }
        } catch (e) {
          print("Error parsing log arrival response: $e");
          logMessage = "Invalid response from arrival logging server.";
        }
      } else {
        logMessage =
            'Server error (${logResponse.statusCode}) logging arrival time.';
        print(
            "_markAsArrived Error [$taskid]: Log Arrival API HTTP Error: ${logResponse.statusCode}");
      }
    } on TimeoutException catch (_) {
      print("_markAsArrived Error [$taskid]: Timeout calling Log Arrival API.");
      logMessage = "Timeout logging arrival time.";
    } on SocketException catch (_) {
      print(
          "_markAsArrived Error [$taskid]: Network error calling Log Arrival API.");
      logMessage = "Network error logging arrival time.";
    } catch (e) {
      print(
          "_markAsArrived Error [$taskid]: Error calling Log Arrival API: $e");
      logMessage = "An unknown error occurred while logging arrival.";
    } finally {
      if (mounted) _hideLoadingDialog(); // Hide marking arrived dialog
    }

    // --- Update Local State ONLY if Log was Successful ---
    if (logSuccess && mounted) {
      print(
          '_markAsArrived [Task $taskid]: Arrival logged successfully. Updating local state.');
      setState(() {
        taskArrivedStatus[taskid] = true;
        taskStartedStatus[taskid] = true;
        taskCompletedStatus[taskid] = false;
        // Distance display already updated by _getRouteInfoFromDistanceMatrix
      });
      _showSuccessSnackBar(logMessage);
    } else if (mounted) {
      print('_markAsArrived [Task $taskid]: Arrival logging failed.');
      _showErrorSnackBar(logMessage); // Show log error
    }
  }

  // 5. Update Transportation Method (API only)
  // --- Core Task Actions ---

// ... (Other functions like _fetchTaskDestination, _startTaskWithLocation, _getRouteInfoFromDistanceMatrix, _markAsArrived remain the same) ...

  // 5. Update Transportation Method (API only) - NO CHANGE NEEDED HERE
  Future<bool> _updateTransportationMethod(String taskid,
      String transportMethod, Position? startPos, Position? destPos) async {
    // ... (Existing logic is correct)
    if (!mounted) return false;
    print(
        "_updateTransportationMethod: Called for task $taskid with method $transportMethod");

    var url = Uri.parse('$baseApiUrl/updatetransport.php');
    bool success = false;

    String startLocationPayload =
        (startPos != null) ? "${startPos.latitude},${startPos.longitude}" : "";
    String taskDestinationPayload =
        (destPos != null) ? "${destPos.latitude},${destPos.longitude}" : "";

    print(
        "_updateTransportationMethod [Task $taskid]: Payload - taskID: $taskid, method: $transportMethod, startLoc: '$startLocationPayload', destLoc: '$taskDestinationPayload'");

    try {
      var response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'taskID': taskid,
              'transportationMethod': transportMethod,
              "currentLocation":
                  startLocationPayload, // User's current location when starting
              "taskDestination":
                  taskDestinationPayload // Geocoded/fetched task location
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return false;
      print(
          "_updateTransportationMethod [Task $taskid]: API Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map && responseBody['success'] == true) {
            success = true;
            print(
                "_updateTransportationMethod [Task $taskid]: Backend reported success.");
          } else {
            success = false;
            print(
                "_updateTransportationMethod [Task $taskid]: Backend reported failure or unexpected format: ${responseBody['message'] ?? 'No message'}");
          }
        } catch (e) {
          success = false;
          print(
              "_updateTransportationMethod [Task $taskid]: Error parsing response: $e");
        }
      } else {
        success = false;
        print(
            '_updateTransportationMethod [Task $taskid]: API request failed! Status Code: ${response.statusCode}.');
      }
    } on TimeoutException catch (_) {
      print("_updateTransportationMethod [Task $taskid]: Timeout error.");
      success = false;
    } on SocketException catch (_) {
      print("_updateTransportationMethod [Task $taskid]: Network error.");
      success = false;
    } catch (e) {
      print("_updateTransportationMethod [Task $taskid]: General error: $e");
      success = false;
    }
    return success;
  }

  // 6. Mark Task as Completed (Fetches coords, Calculates distance via API, Sends distance to Backend)
  Future<void> _markAsCompleted(String taskid) async {
    if (!mounted) return;
    print("_markAsCompleted: Called for task $taskid");
    _showLoadingDialog("Preparing to Complete Task..."); // Initial dialog

    Position? fetchedStartPosition;
    Position? fetchedDestinationPosition;
    String fetchCoordsMessage =
        "Error fetching task coordinates for completion.";
    bool coordsFetchSuccess = false;
    int? taskIdInt = int.tryParse(taskid);

    // --- 1. Fetch Coordinates from checkarrivaldistance.php ---
    if (taskIdInt == null) {
      if (mounted) _hideLoadingDialog();
      if (mounted)
        _showErrorSnackBar(
            "Invalid task ID format for coordinate fetch: $taskid");
      return;
    }

    var checkUrl = Uri.parse('$baseApiUrl/checkarrivaldistance.php');
    print(
        '_markAsCompleted [Task $taskid]: Calling Check Arrival API (for coords): $checkUrl');

    try {
      final checkResponse = await http
          .post(
            checkUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode({'taskID': taskIdInt}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) {
        _hideLoadingDialog();
        return;
      } // Check mount after await

      print(
          '_markAsCompleted [Task $taskid]: Check Arrival API Response (${checkResponse.statusCode}): ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        final responseBody = json.decode(checkResponse.body);
        String? startCoordsFromServer =
            responseBody['startLocation'] as String?;
        String? destCoordsStr = responseBody['destinationLocation'] as String?;

        fetchedStartPosition = _parseCoordsToPosition(startCoordsFromServer);
        fetchedDestinationPosition = _parseCoordsToPosition(destCoordsStr);

        if (fetchedStartPosition != null &&
            fetchedDestinationPosition != null) {
          print(
              "_markAsCompleted [Task $taskid]: Start coordinates fetched: ${fetchedStartPosition.latitude}, ${fetchedStartPosition.longitude}");
          print(
              "_markAsCompleted [Task $taskid]: Destination coordinates fetched: ${fetchedDestinationPosition.latitude}, ${fetchedDestinationPosition.longitude}");
          coordsFetchSuccess = true;
        } else {
          fetchCoordsMessage =
              "Invalid location data received from server for completion.";
          print(
              "_markAsCompleted Error [$taskid]: Failed to parse coords for completion. Start: '$startCoordsFromServer', Dest: '$destCoordsStr'");
          coordsFetchSuccess = false;
        }
      } else {
        fetchCoordsMessage =
            'Server error (${checkResponse.statusCode}) fetching task coordinates.';
        print(
            "_markAsCompleted Error [$taskid]: Check Arrival API HTTP Error: ${checkResponse.statusCode}");
        coordsFetchSuccess = false;
      }
    } on TimeoutException catch (_) {
      print(
          "_markAsCompleted Error [$taskid]: Timeout calling Check Arrival API for coords.");
      fetchCoordsMessage = "Timeout fetching task coordinates.";
      coordsFetchSuccess = false;
    } on SocketException catch (_) {
      print(
          "_markAsCompleted Error [$taskid]: Network error calling Check Arrival API for coords.");
      fetchCoordsMessage = "Network error fetching task coordinates.";
      coordsFetchSuccess = false;
    } catch (e) {
      print(
          "_markAsCompleted Error [$taskid]: Error calling Check Arrival API for coords: $e");
      fetchCoordsMessage =
          "An unknown error occurred fetching task coordinates.";
      coordsFetchSuccess = false;
    }

    if (!mounted) return; // Check again after async fetch

    if (!coordsFetchSuccess) {
      _hideLoadingDialog();
      _showErrorSnackBar(fetchCoordsMessage);
      return;
    }

    // --- 2. Calculate Distance between fetched Start and Destination using Distance Matrix API ---
    _hideLoadingDialog(); // Hide coord fetching dialog
    _showLoadingDialog("Calculating Final Distance...");
    int? calculatedDistanceMeters;
    String distanceCalcMessage = "Error calculating final distance.";
    bool distanceCalcSuccess = false;

    // Call the existing function, but pass the FETCHED start and destination positions
    Map<String, dynamic> routeInfo = await _getRouteInfoFromDistanceMatrix(
        taskid,
        fetchedStartPosition!, // Known non-null due to coordsFetchSuccess check
        fetchedDestinationPosition! // Known non-null
        );

    if (!mounted) {
      _hideLoadingDialog();
      return;
    } // Check mount after await

    if (routeInfo['success'] == true && routeInfo['distance_meters'] != null) {
      calculatedDistanceMeters = routeInfo['distance_meters'];
      distanceCalcSuccess = true;
      print(
          "_markAsCompleted [Task $taskid]: Final distance calculated via API: $calculatedDistanceMeters meters.");
    } else {
      distanceCalcMessage =
          routeInfo['message'] ?? 'Failed to calculate final distance.';
      print(
          "_markAsCompleted Error [$taskid]: Distance Matrix API failed for final calculation: $distanceCalcMessage");
      distanceCalcSuccess = false;
    }

    if (!distanceCalcSuccess) {
      _hideLoadingDialog();
      _showErrorSnackBar(distanceCalcMessage);
      return;
    }

    // --- 3. Send Completion Data (including calculated distance) to Backend ---
    _hideLoadingDialog(); // Hide distance calc dialog
    _showLoadingDialog("Completing Task..."); // Final dialog for API call

    String completeTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    // *** Use the SAME endpoint for now, assuming you will modify it to accept the distance ***
    // *** If you create a *new* PHP file, update the URL here. ***
    var url = Uri.parse('$baseApiUrl/completetask.php');
    print(
        "_markAsCompleted [Task $taskid]: Sending completion data (with distance) to $url");

    try {
      var response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'taskID': taskid,
              'completeTime': completeTime,
              'distance': calculatedDistanceMeters
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        _hideLoadingDialog();
        return;
      }
      _hideLoadingDialog(); // Hide after API call

      print(
          "_markAsCompleted [Task $taskid]: Final Completion API Response (${response.statusCode}): ${response.body}");

      // --- 4. Handle Response and Update UI ---
      if (response.statusCode == 200) {
        bool backendSuccess = false;
        String backendMessage = "Task completed successfully!";
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map && responseBody['success'] == true) {
            backendSuccess = true;
            backendMessage = responseBody['message'] ?? backendMessage;
          } else {
            backendMessage =
                "Completion failed: ${responseBody['message'] ?? 'Unknown reason'}";
          }
        } catch (e) {
          backendMessage = "Invalid response format from completion server.";
          print(
              "_markAsCompleted [Task $taskid]: Error parsing final response: $e");
        }

        if (backendSuccess && mounted) {
          print(
              "_markAsCompleted [Task $taskid]: Backend success. Updating local state.");
          setState(() {
            taskCompletedStatus[taskid] = true;
            taskArrivedStatus[taskid] =
                true; // Mark arrived implicitly on complete
            taskStartedStatus[taskid] =
                true; // Mark started implicitly on complete
            taskArrivalDistancesKM
                .remove(taskid); // Remove any lingering displayed distance
          });
          _showSuccessSnackBar(backendMessage);
          // Trigger refresh to potentially remove the card from the list
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              print("Triggering task refresh after completion delay.");
              setState(() => _tasksFuture = fetchTasks());
            }
          });
        } else if (mounted) {
          print(
              '_markAsCompleted [Task $taskid]: Backend reported failure or JSON parse error.');
          _showErrorSnackBar(backendMessage);
        }
      } else {
        print(
            '_markAsCompleted [Task $taskid]: Final Completion API request failed! Status Code: ${response.statusCode}.');
        if (mounted)
          _showErrorSnackBar(
              'Failed to complete task (Server Error ${response.statusCode}).');
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorSnackBar('Request timed out while completing task.');
      }
    } on SocketException catch (_) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorSnackBar('Network error. Please check connection.');
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorSnackBar(
            'An error occurred while completing the task: ${e.toString()}');
      }
    } finally {
      // Extra safety check to hide dialog if an error occurred unexpectedly early
      if (mounted && Navigator.of(context).canPop()) {
        try {
          // Attempt to pop only if we suspect a dialog might be open.
          // This is a bit heuristic. A more robust way involves managing dialog state.
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            // Check if the current route *is* the dialog route, might not work perfectly
          } else {
            // If not on the main screen, maybe a dialog is open
            // Navigator.of(context, rootNavigator: true).pop();
          }
          // For simplicity now, just attempt to hide, catching errors
          _hideLoadingDialog();
        } catch (e) {
          print("Error hiding loading dialog in finally (ignorable): $e");
        }
      }
    }
  }
} // End of _ProjectDetailScreenState
