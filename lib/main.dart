import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/employee/emphomescreen.dart';
import 'package:smart_hr/loginpage.dart';

void main() {
  runApp(const MyApp());
}

class UserInfo {
  final String? role;
  final String? userId;

  UserInfo({this.role, this.userId});
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      print("Location permission granted");
    } else if (status.isDenied) {
      print("Location permission denied");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xffeef444c)),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: checkSavedValues(),
        builder: (context, AsyncSnapshot<UserInfo?> snapshot)
        {
          if (snapshot.connectionState == ConnectionState.done)
          {
            final userInfo = snapshot.data;
            if (userInfo != null && userInfo.role != null) {
              if (userInfo.role == 'admin') {
                return HomeScreen();
              } else if (userInfo.role == 'employee') {
                return emphomescreen(userInfo.userId!);
              }
            }
            return const LoginPage();
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  Future<UserInfo?> checkSavedValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    String? userId = prefs.getString('id');

    await prefs.clear();
    print('All SharedPreferences values have been cleared');

    print('Saved Role: $role');
    print('User ID: $userId');

    return UserInfo(role: role, userId: userId);
  }
}