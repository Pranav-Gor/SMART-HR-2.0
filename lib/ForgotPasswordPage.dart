import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final Color primary = const Color(0xffeef444c);
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/check_email.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text}),
      );

      print('Email check response: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        // Email exists, send OTP
        final otpResponse = await http.post(
          Uri.parse('http://192.168.29.211/hr_api/otp.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
          }),
        );

        print('OTP response: ${otpResponse.body}');

        final Map<String, dynamic> otpData = jsonDecode(otpResponse.body);

        setState(() {
          _isLoading = false;
        });

        if (otpData['success'] == true) {
          // Extract OTP from response if it's included
          final String? otp = otpData['otp']?.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP sent successfully')),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                email: _emailController.text,
                primary: primary,
                otp: otp,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = otpData['message'] ?? 'Failed to send OTP';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = responseData['message'] ?? 'Email not found';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight / 3.2,
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
                    Center(
                      child: Text(
                        "Forgot Password",
                        style: TextStyle(
                          fontSize: screenWidth / 18,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: screenWidth / 26,
                        fontFamily: "NexaBold",
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildInputField(
                      controller: _emailController,
                      hintText: "Enter your email",
                      icon: Icons.email,
                      validator: _validateEmail,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoading ? null : _sendRecoveryEmail,
                      child: Container(
                        height: 50,
                        width: screenWidth,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  "Send Recovery Email",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    letterSpacing: 1,
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
    required String? Function(String?)? validator,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Icon(icon, color: primary, size: 24),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                errorStyle: TextStyle(height: 0), // Hide default error text
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  final String email;
  final Color primary;
  final String? otp;

  OtpPage({
    required this.email,
    required this.primary,
    this.otp,
  });

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String _enteredOtp = '';
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _verifyOtp(String enteredOtp) async {
    if (enteredOtp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      if (widget.otp != null && widget.otp == enteredOtp) {
        setState(() {
          _isVerifying = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: widget.email),
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/verify_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': enteredOtp,
        }),
      );

      print('Verification response: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _isVerifying = false;
      });

      if (responseData['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: widget.email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Invalid OTP';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Failed to verify OTP. Please try again.';
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("OTP Verification"),
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double usableWidth = constraints.maxWidth;
          final double usableHeight = constraints.maxHeight;

          final double headerHeight = usableHeight * 0.32;
          final double fontSize = usableWidth * 0.045;
          final double buttonHeight = usableHeight * 0.07;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: headerHeight,
                  width: usableWidth,
                  decoration: BoxDecoration(
                    color: widget.primary,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(usableWidth * 0.2),
                      bottomLeft: Radius.circular(usableWidth * 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: usableHeight * 0.03),
                      SizedBox(
                        height: usableHeight * 0.22,
                        child: Lottie.asset("assets/logingif.json"),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: usableWidth * 0.08),
                  child: Column(
                    children: [
                      SizedBox(height: usableHeight * 0.05),
                      Text(
                        "Enter OTP sent to\n${widget.email}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: "NexaBold",
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.025),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: usableWidth * 0.9,
                          child: OtpTextField(
                            numberOfFields: 6,
                            borderColor: widget.primary,
                            showFieldAsBox: true,
                            fieldWidth: usableWidth * 0.11,
                            onCodeChanged: (String code) {
                              setState(() {
                                _enteredOtp = code;
                              });
                            },
                            onSubmit: (String verificationCode) {
                              _verifyOtp(verificationCode);
                            },
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(top: usableHeight * 0.01),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: usableWidth * 0.035,
                            ),
                          ),
                        ),
                      SizedBox(height: usableHeight * 0.05),
                      _isVerifying
                          ? CircularProgressIndicator(color: widget.primary)
                          : ElevatedButton(
                              onPressed: () {
                                if (_enteredOtp.length == 6) {
                                  _verifyOtp(_enteredOtp);
                                } else {
                                  setState(() {
                                    _errorMessage = 'Please enter all 6 digits';
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.primary,
                                minimumSize: Size(usableWidth, buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Verify OTP",
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String email;

  ResetPasswordPage({required this.email});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final Color primary = const Color(0xffeef444c);
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.211/hr_api/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': _passwordController.text,
        }),
      );

      print('Reset password response: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset successfully')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to reset password';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Reset Password"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
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
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Lottie.asset("assets/logingif.json"),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight / 15),
                    Text(
                      "Create a New Password",
                      style: TextStyle(
                        fontSize: screenWidth / 18,
                        fontFamily: "NexaBold",
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: _passwordController,
                      hintText: "Enter new password",
                      icon: Icons.lock,
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hintText: "Confirm new password",
                      icon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      validator: _validateConfirmPassword,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: _isLoading ? null : _resetPassword,
                      child: Container(
                        height: 50,
                        width: screenWidth,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Reset Password",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    letterSpacing: 1,
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
    required bool obscureText,
    required String? Function(String?)? validator,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Icon(icon, color: primary, size: 24),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                errorStyle: TextStyle(height: 0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: primary,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ],
      ),
    );
  }
}
