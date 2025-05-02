import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hr/ForgotPasswordPage.dart';
import 'package:smart_hr/admin/homescreen.dart';
import 'package:smart_hr/employee/emphomescreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  int _failedAttempts = 0;
  bool _loginDisabled = false;
  int _timerCount = 30;
  Timer? _timer;
  String? _loginError; // Added for login error message

  double screenHeight = 0;
  double screenWidth = 0;
  final Color primary = const Color(0xffeef444c);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  void _startTimer() {
    _timerCount = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerCount > 0) {
          _timerCount--;
        } else {
          _timer?.cancel();
          _loginDisabled = false;
          _failedAttempts = 0;
          _loginError = null; // Clear error when timer expires
        }
      });
    });
  }

  Future<void> _login() async {
    if (_loginDisabled) {
      setState(() {
        _loginError = 'Login disabled. Try again in $_timerCount seconds';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear previous errors
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/login.php'),
        body: {'email': email, 'password': password},
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          _failedAttempts = 0;
          await saveIdAndRole(
              responseData['userid'].toString(), responseData['role']);

          if (responseData['role'] == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            String userid = responseData['userid'].toString();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => emphomescreen(userid)),
            );
          }
        } else {
          setState(() {
            _failedAttempts++;
            _loginError =
                responseData['message'] ?? 'Invalid email or password';
          });

          if (_failedAttempts >= 3) {
            setState(() {
              _loginDisabled = true;
              _loginError =
                  'Too many failed attempts. Redirecting to password recovery...';
            });
            _startTimer();
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
              );
            });
          }
        }
      } else {
        setState(() {
          _failedAttempts++;
          _loginError = 'Server error. Please try again.';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _failedAttempts++;
        _loginError = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveIdAndRole(String id, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', id);
    await prefs.setString('role', role);
    print('Saved ID: $id');
    print('Saved Role: $role');
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight / 2.4,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(80),
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                height: MediaQuery.of(context).size.height * 0.3,
                child: Lottie.asset("assets/logingif.json"),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight / 15),
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: screenWidth / 15,
                        fontFamily: "NexaBold",
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Please sign in to continue",
                      style: TextStyle(
                        fontSize: screenWidth / 26,
                        fontFamily: "NexaRegular",
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: _emailController,
                      hintText: "Enter your Email",
                      icon: Icons.email_outlined,
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: _passwordController,
                      hintText: "Enter your password",
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureText,
                      isPassword: true,
                      validator: _validatePassword,
                    ),
                    // Login error message
                    if (_loginError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _loginError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(height: 1),
                    TextButton(
                      onPressed: _loginDisabled
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage()),
                              );
                            },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: _loginDisabled ? Colors.grey : Colors.black),
                      ),
                    ),
                    if (_loginDisabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Login disabled for $_timerCount seconds',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: screenHeight / 50),
                    GestureDetector(
                      onTap: _loginDisabled ? null : _login,
                      child: Container(
                        height: 60,
                        width: screenWidth,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _loginDisabled
                                  ? Colors.grey.withOpacity(0.5)
                                  : Colors.red.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 3,
                              offset: Offset(3, 4),
                            ),
                          ],
                          color: _loginDisabled ? Colors.grey : Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 20,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 3,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: screenWidth / 6,
                child: Icon(icon, color: primary, size: screenWidth / 15),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  validator: validator,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
