import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/employee/employeedrawer.dart';

class todayscreen extends StatefulWidget {
  const todayscreen({Key? key, required this.employeeId}) : super(key: key);

  final String employeeId;

  @override
  State<todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<todayscreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool isDataMatched = false;
  String location = " ";
  String scanResult = " ";
  String officeCode = " ";
  late ConfettiController _confettiController;
  MobileScannerController cameraController = MobileScannerController();

  String qrData = '';
  String firstName = "";
  String lastName = "";
  DateTime? checkInTimestamp;
  DateTime? checkOutTimestamp;
  Uint8List? profilePicBytes;
  String profilePicLink = "";
  List<Map<String, dynamic>> attendanceData = [];
  bool isQRValid = false;
  bool isScanning = false;

  Color primary = const Color(0xffeef444c);

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    qrfetch();
    fetchEmployeeData();
    _restoreSession().then((_) {
      fetchAttendanceData().then((_) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _getLocation() async {
    List<Placemark> placemark =
    await placemarkFromCoordinates(emphomescreen.lat, emphomescreen.long);

    setState(() {
      location =
      "${placemark[0].street},${placemark[0].administrativeArea},${placemark[0].postalCode},${placemark[0].country}";
    });
  }

  Future<void> _saveSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (checkInTimestamp != null) {
      await prefs.setString(
          'checkInTimestamp', checkInTimestamp!.toIso8601String());
    } else {
      await prefs.remove('checkInTimestamp');
    }
    if (checkOutTimestamp != null) {
      await prefs.setString(
          'checkOutTimestamp', checkOutTimestamp!.toIso8601String());
    } else {
      await prefs.remove('checkOutTimestamp');
    }
    await prefs.setBool('isQRValid', isQRValid);
    await prefs.setBool('isDataMatched', isDataMatched);
  }

  Future<void> _destroySession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('checkInTimestamp');
    await prefs.remove('checkOutTimestamp');
    await prefs.remove('isQRValid');
    await prefs.remove('isDataMatched');
  }

  Future<void> _restoreSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? checkInStr = prefs.getString('checkInTimestamp');
    String? checkOutStr = prefs.getString('checkOutTimestamp');
    bool? qrValid = prefs.getBool('isQRValid');
    bool? dataMatched = prefs.getBool('isDataMatched');

    if (checkInStr != null) {
      checkInTimestamp = DateTime.parse(checkInStr);
    }
    if (checkOutStr != null) {
      checkOutTimestamp = DateTime.parse(checkOutStr);
    }
    setState(() {
      isQRValid = qrValid ?? false;
      isDataMatched = dataMatched ?? false;
    });
  }

  Future<void> fetchAttendanceData() async {
    try {
      DateTime today = DateTime.now();
      String todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
          'http://192.168.29.211/hr_api/get_attendance_by_date_user.php?userID=${widget.employeeId}&date=$todayStr');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is Map && jsonData.isNotEmpty) {
          checkInTimestamp ??= jsonData['checkIn'] != null
              ? DateTime.parse(jsonData['checkIn'])
              : null;
          checkOutTimestamp ??= jsonData['checkOut'] != null
              ? DateTime.parse(jsonData['checkOut'])
              : null;

          isDataMatched = true;
        } else if (jsonData is List && jsonData.isNotEmpty) {
          // Handle case where response is a list
          var firstRecord = jsonData[0];
          checkInTimestamp ??= firstRecord['checkIn'] != null
              ? DateTime.parse(firstRecord['checkIn'])
              : null;
          checkOutTimestamp ??= firstRecord['checkOut'] != null
              ? DateTime.parse(firstRecord['checkOut'])
              : null;

          isDataMatched = true;
        } else {
          checkInTimestamp ??= null;
          checkOutTimestamp ??= null;
          isDataMatched = false;
        }
      } else {
        throw Exception(
            'Failed to fetch attendance data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching attendance data: $error');
    }
  }

  Future<void> qrfetch() async {
    final response = await http
        .get(Uri.parse('http://192.168.29.211/hr_api/fetchqrcode_admin.php'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> qrdataList = [data];

      setState(() {
        qrData = json.encode(qrdataList);
      });
    } else {
      throw Exception('Failed to fetch data');
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

        if (employeeData == null) {
          throw Exception(
              'Employee data not found for user ID: ${widget.employeeId}');
        }

        final String? userFirstName = employeeData['firstName'];
        final String? userLastName = employeeData['lastName'];

        print(
            "Employee data fetched successfully for ID: ${widget.employeeId}");

        setState(() {
          firstName = userFirstName ?? "";
          lastName = userLastName ?? "";
        });
      } else {
        print(
            "Failed to fetch employee data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employee data: $e')),
      );
    }
  }


  void _startQRScan() {
    setState(() {
      isScanning = true;
    });

    // Listen for barcodes
    cameraController.barcodes.listen((barcodeCapture) {
      for (final barcode in barcodeCapture.barcodes) {
        final String? code = barcode.rawValue;
        if (code == null) {
          print('Failed to scan QR code');
        } else {
          print('Scanned QR code: $code');
          _processScannedQR(code);
        }
      }
    });
  }

  Future<void> _processScannedQR(String code) async {
    if (!isScanning) return;

    setState(() {
      isScanning = false;
    });

    bool match = await _checkQRData(code);

    if (match) {
      setState(() {
        scanResult = code;
        isQRValid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code Verified! Slide to Check In.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      setState(() {
        isQRValid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The scanned data does not match!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _checkQRData(String qrData) async {
    if (qrData.isEmpty || qrData == "-1") {
      return false;
    }
    try {
      final response = await http.get(
        Uri.parse('http://192.168.29.211/hr_api/fetchqrcode_admin.php'),
        headers: {'Cache-Control': 'no-cache'},
      );

      if (response.statusCode == 200) {
        print("API Response: ${response.body}");

        var decodedResponse = json.decode(response.body);
        String mysqlData = '';

        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey("qrcode")) {
          mysqlData = decodedResponse["qrcode"].toString().trim().toLowerCase();
        }

        print("MySQL QR Data: $mysqlData");
        print("Scanned QR Data: ${qrData.trim().toLowerCase()}");

        String baseScannedQR = qrData.trim().toLowerCase();
        if (baseScannedQR.length > mysqlData.length) {
          baseScannedQR = baseScannedQR.substring(0, baseScannedQR.length - 1);
        }

        bool isMatch = mysqlData.startsWith(baseScannedQR);
        print("Base Scanned QR: $baseScannedQR");
        print("Match Result: $isMatch");

        return isMatch;
      } else {
        print('Error fetching QR data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking QR data: $e');
      return false;
    }
  }

  Future<void> _saveTimestamp(String type) async {
    DateTime? timestamp =
    type == "checkIn" ? checkInTimestamp : checkOutTimestamp;

    if (timestamp == null) {
      print('Error: Timestamp is null for type: $type');
      return;
    }

    String timestampStr = timestamp.toIso8601String();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/savetimestamp.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userID': widget.employeeId,
          'timestamp': timestampStr,
          'type': type.toLowerCase(),
        }),
      );

      if (response.statusCode == 200 && json.decode(response.body)['success']) {
        if (type == "checkIn") {
          _saveSession();
        } else if (type == "checkOut") {
          _destroySession();
          _confettiController.play();
        }
      }
    } catch (e) {
      print('Error saving timestamp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Welcome, ",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "NexaRegular",
                          fontSize: screenWidth / 20,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$firstName $lastName",
                        style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 18,
                            color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: isDataMatched,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 32),
                    child: Text(
                      "Today's Status",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 18,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: isDataMatched,
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 32),
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Check In",
                                style: TextStyle(
                                  fontFamily: "NexaRegular",
                                  fontSize: screenWidth / 20,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                checkInTimestamp != null
                                    ? DateFormat('hh:mm a')
                                    .format(checkInTimestamp!)
                                    : "--/--",
                                style: TextStyle(
                                  fontFamily: "NexaBold",
                                  fontSize: screenWidth / 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Check Out",
                                style: TextStyle(
                                  fontFamily: "NexaRegular",
                                  fontSize: screenWidth / 20,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                checkOutTimestamp != null
                                    ? DateFormat('hh:mm a')
                                    .format(checkOutTimestamp!)
                                    : "--/--",
                                style: TextStyle(
                                  fontFamily: "NexaBold",
                                  fontSize: screenWidth / 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      text: DateTime.now().day.toString(),
                      style: TextStyle(
                        color: primary,
                        fontSize: screenWidth / 18,
                        fontFamily: "NexaBold",
                      ),
                      children: [
                        TextSpan(
                          text:
                          DateFormat('  MMMM  yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth / 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('hh:mm:ss a').format(DateTime.now()),
                        style: TextStyle(
                          fontFamily: "NexaRegular",
                          fontSize: screenWidth / 20,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
                if (isQRValid && checkInTimestamp == null)
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Builder(builder: (context) {
                      final GlobalKey<SlideActionState> key = GlobalKey();
                      return SlideAction(
                        text: "Slide to Check In",
                        textStyle: TextStyle(
                          color: Colors.black54,
                          fontSize: screenWidth / 20,
                          fontFamily: "NexaRegular",
                        ),
                        outerColor: Colors.white,
                        innerColor: primary,
                        key: key,
                        onSubmit: () {
                          if (checkInTimestamp == null) {
                            setState(() {
                              checkInTimestamp = DateTime.now();
                              isDataMatched = true;
                            });
                            _saveTimestamp("checkIn");
                          }
                          _getLocation();
                        },
                      );
                    }),
                  ),
                if (checkInTimestamp != null && checkOutTimestamp == null)
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Builder(builder: (context) {
                      final GlobalKey<SlideActionState> key = GlobalKey();
                      return SlideAction(
                        text: "Slide to Check Out",
                        textStyle: TextStyle(
                          color: Colors.black54,
                          fontSize: screenWidth / 20,
                          fontFamily: "NexaRegular",
                        ),
                        outerColor: Colors.white,
                        innerColor: primary,
                        key: key,
                        onSubmit: () {
                          if (checkOutTimestamp == null) {
                            setState(() {
                              checkOutTimestamp = DateTime.now();
                            });
                            _saveTimestamp("checkOut");
                          }
                          _getLocation();
                        },
                      );
                    }),
                  ),
                if (checkInTimestamp != null && checkOutTimestamp != null)
                  Container(
                    margin: const EdgeInsets.only(top: 32, bottom: 32),
                    child: Text(
                      "You have completed this day!",
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                location != " " ? Text("Location: $location") : SizedBox(),
                if (!isQRValid && checkInTimestamp == null)
                  GestureDetector(
                    onTap: () {
                      _showQRScanner();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 135),
                      height: screenWidth / 1.7,
                      width: screenWidth / 1.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                            spreadRadius: 9,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: screenWidth / 4,
                            height: screenWidth / 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.1),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.expand,
                                  size: screenWidth / 6,
                                  color: primary.withOpacity(0.8),
                                ),
                                Icon(
                                  FontAwesomeIcons.camera,
                                  size: screenWidth / 12,
                                  color: primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Scan QR to Check in",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                fontSize: screenWidth / 20,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Align QR code within frame",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "NexaRegular",
                              fontSize: screenWidth / 30,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // QR Scanner Overlay
          if (isScanning)
            Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _processScannedQR(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon:
                    const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      setState(() {
                        isScanning = false;
                      });
                    },
                  ),
                ),
                Center(
                  child: Container(
                    width: screenWidth * 0.7,
                    height: screenWidth * 0.7,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    setState(() {
      isScanning = true;
    });
    _startQRScan();
  }
}
