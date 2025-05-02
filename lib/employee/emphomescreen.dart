import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:smart_hr/employee/calanderscreen.dart';
import 'package:smart_hr/employee/profilescreen.dart';
import 'package:smart_hr/employee/todayscreen.dart';
import 'package:smart_hr/employee/employeedrawer.dart';
import 'package:smart_hr/employee/location_service.dart';

class emphomescreen extends StatefulWidget {
  final String userid;
  static double lat = 0;
  static double long = 0;

  const emphomescreen(this.userid, {super.key});

  @override
  _emphomescreenState createState() => _emphomescreenState();
}

class _emphomescreenState extends State<emphomescreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color(0xffeef444c);
  int currentIndex = 1;
  late PageController _pageController;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.userLarge,
  ];

  @override
  void initState() {
    super.initState();
    String userid = widget.userid;
    _startLocationService();
    _getUsernameData();
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startLocationService() async {
    await LocationService().initialize();

    LocationService().getLongitude().then((value) {
      setState(() {
        emphomescreen.long = value!;
      });

      LocationService().getLatitude().then((value) {
        setState(() {
          emphomescreen.lat = value!;
        });
      });
    });
  }

  void _getUsernameData() async {
    String userid = widget.userid;
    print("userID:$userid");
    final response = await http.post(
      Uri.parse('http://192.168.29.211/hr_api/login.php'),
      body: {'userID': userid},
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Smart HR',
          style: TextStyle(fontFamily: "NexaRegular", color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: MyDrawer(
        employeeId: widget.userid,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          CalendarScreen(employeeId: widget.userid),
          todayscreen(employeeId: widget.userid),
          profilescreen(employeeId: widget.userid),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(50)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i],
                              color:
                                  i == currentIndex ? primary : Colors.black54,
                              size: i == currentIndex ? 27 : 22,
                            ),
                            i == currentIndex
                                ? Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    height: 6,
                                    width: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(40)),
                                      color: primary,
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              }
            ],
          ),
        ),
      ),
    );
  }
}
