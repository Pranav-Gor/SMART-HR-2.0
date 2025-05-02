import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class registrationpage extends StatefulWidget {
  const registrationpage({super.key});

  @override
  State<registrationpage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<registrationpage> {
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _basicSalaryController = TextEditingController();

  // Dropdown values
  String? selectedDepartment;
  String? selectedJobTitle;
  String? selectedGender;

  // Lists for dropdowns
  List<String> departments = [];
  List<String> genders = ['Male', 'Female', 'Other'];
  List<Map<String, String>> allJobTitles = [];
  List<String> filteredJobTitles = [];

  // Validation errors
  String? _firstNameError;
  String? _lastNameError;
  String? _dobError;
  String? _contactError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _addressError;
  String? _salaryError;
  String? _departmentError;
  String? _jobTitleError;
  String? _genderError;

  // Other variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;
  Color primary = const Color(0xffeef444c);
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchDepartments();
    fetchJobTitles();
  }

  // Validation methods
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'Minimum 2 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Minimum 2 characters';
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Enter 10 digit number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Minimum 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'At least one uppercase';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'At least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'At least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Enter complete address';
    }
    return null;
  }

  String? _validateSalary(String? value) {
    if (value == null || value.isEmpty) {
      return 'Salary is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter valid amount';
    }
    if (double.parse(value) <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select $fieldName';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _firstNameError = _validateFirstName(_firstNameController.text);
      _lastNameError = _validateLastName(_lastNameController.text);
      _dobError = _validateDob(_dobController.text);
      _contactError = _validateContact(_contactNumberController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError =
          _validateConfirmPassword(_confirmPasswordController.text);
      _addressError = _validateAddress(_addressController.text);
      _salaryError = _validateSalary(_basicSalaryController.text);
      _departmentError = _validateDropdown(selectedDepartment, 'department');
      _jobTitleError = _validateDropdown(selectedJobTitle, 'job title');
      _genderError = _validateDropdown(selectedGender, 'gender');
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _dobError == null &&
        _contactError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _addressError == null &&
        _salaryError == null &&
        _departmentError == null &&
        _jobTitleError == null &&
        _genderError == null;
  }

  // API methods
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
                      'jobtitle': job['title'].toString(),
                      'department': job['deptName'].toString()
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error fetching job titles: $e');
    }
  }

  void filterJobTitles() {
    setState(() {
      filteredJobTitles = allJobTitles
          .where((job) => job['department'] == selectedDepartment)
          .map((job) => job['jobtitle']!)
          .toList();
      selectedJobTitle = null;
      _jobTitleError = null;
    });
  }

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
                .toSet()
                .toList();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error fetching departments: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _dobError = null;
      });
    }
  }

  Future<void> _insertRecord() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await API().insertRecord(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _dobController.text.trim(),
        _contactNumberController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _addressController.text.trim(),
        selectedJobTitle!,
        selectedDepartment!,
        _basicSalaryController.text.trim(),
        "Employee",
        selectedGender!,
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          _showSnackBar('Employee registered successfully', isError: false);
          _clearForm();
        } else {
          _showSnackBar(responseData['message'] ?? 'Registration failed');
        }
      } else {
        _showSnackBar('Failed to register: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error registering employee: $e');
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _dobController.clear();
    _contactNumberController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _addressController.clear();
    _basicSalaryController.clear();
    setState(() {
      selectedDepartment = null;
      selectedJobTitle = null;
      selectedGender = null;
      _selectedDate = null;
      _firstNameError = null;
      _lastNameError = null;
      _dobError = null;
      _contactError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _addressError = null;
      _salaryError = null;
      _departmentError = null;
      _jobTitleError = null;
      _genderError = null;
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // UI Components
  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? errorText,
    bool showVisibilityToggle = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.red),
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                suffixIcon: showVisibilityToggle
                    ? IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: onVisibilityToggle,
                      )
                    : null,
                errorStyle: const TextStyle(height: 0),
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                errorText,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Date of Birth",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              width: 400,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(2, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child:
                        Icon(Icons.calendar_today_outlined, color: Colors.red),
                  ),
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : "Select date",
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_dobError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                _dobError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required IconData icon,
    required String label,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              value: value,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 50,
                width: 400,
                padding: const EdgeInsets.only(left: 15, right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.arrow_circle_down_rounded),
                iconEnabledColor: Colors.black,
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                offset: const Offset(0, -4),
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                errorText,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 7,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Registration',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NexaBold',
          ),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 5,
                      bottom: 20,
                      child: Lottie.asset(
                        "assets/registration.json",
                        width: 150,
                        height: 150,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Register New Employee",
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: "NexaBold",
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Fill in the details below",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Sections
              _buildFormCard(
                title: "Personal Information",
                children: [
                  _buildTextFieldWithIcon(
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                    label: "First Name",
                    hint: "Enter first name",
                    errorText: _firstNameError,
                  ),
                  _buildTextFieldWithIcon(
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                    label: "Last Name",
                    hint: "Enter last name",
                    errorText: _lastNameError,
                  ),
                  _buildDateField(),
                  _buildDropdownField(
                    value: selectedGender,
                    icon: Icons.wc,
                    label: "Gender",
                    hint: "Select gender",
                    items: genders,
                    onChanged: (newValue) {
                      setState(() {
                        selectedGender = newValue;
                        _genderError = null;
                      });
                    },
                    errorText: _genderError,
                  ),
                  _buildTextFieldWithIcon(
                    controller: _contactNumberController,
                    icon: Icons.phone_android_outlined,
                    label: "Contact Number",
                    hint: "Enter phone number",
                    keyboardType: TextInputType.phone,
                    errorText: _contactError,
                  ),
                ],
              ),

              _buildFormCard(
                title: "Account Information",
                children: [
                  _buildTextFieldWithIcon(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    label: "Email",
                    hint: "Enter email address",
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  _buildTextFieldWithIcon(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    label: "Password",
                    hint: "Create password",
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    showVisibilityToggle: true,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  _buildTextFieldWithIcon(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    label: "Confirm Password",
                    hint: "Confirm password",
                    obscureText: _obscureConfirmPassword,
                    errorText: _confirmPasswordError,
                    showVisibilityToggle: true,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  _buildTextFieldWithIcon(
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    label: "Address",
                    hint: "Enter full address",
                    errorText: _addressError,
                  ),
                ],
              ),

              _buildFormCard(
                title: "Employment Information",
                children: [
                  _buildDropdownField(
                    value: selectedDepartment,
                    icon: Icons.work_outline,
                    label: "Department",
                    hint: "Select department",
                    items: departments,
                    onChanged: (newValue) {
                      setState(() {
                        selectedDepartment = newValue;
                        _departmentError = null;
                        filterJobTitles();
                      });
                    },
                    errorText: _departmentError,
                  ),
                  _buildDropdownField(
                    value: selectedJobTitle,
                    icon: Icons.badge_outlined,
                    label: "Job Title",
                    hint: "Select job title",
                    items: filteredJobTitles,
                    onChanged: (newValue) {
                      setState(() {
                        selectedJobTitle = newValue;
                        _jobTitleError = null;
                      });
                    },
                    errorText: _jobTitleError,
                  ),
                  _buildTextFieldWithIcon(
                    controller: _basicSalaryController,
                    icon: Icons.currency_rupee_rounded,
                    label: "Basic Salary",
                    hint: "Enter salary amount",
                    keyboardType: TextInputType.number,
                    errorText: _salaryError,
                  ),
                ],
              ),

              // Register Button
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _insertRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "REGISTER EMPLOYEE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class API {
  final String baseUrl = 'http://192.168.29.211/hr_api';

  Future<http.Response> insertRecord(
    String firstname,
    String lastname,
    String bod,
    String contactnumber,
    String email,
    String password,
    String address,
    String jobtitle,
    String department,
    String basicsalary,
    String role,
    String gender,
  ) async {
    final uri = Uri.parse('$baseUrl/registration.php');

    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "firstname": firstname,
        "lastname": lastname,
        "birthdate": bod,
        "contactnumber": contactnumber,
        "email": email,
        "password": password,
        "address": address,
        "departmentname": department,
        "jobtitle": jobtitle,
        "netsalary": basicsalary,
        "role": role,
        "gender": gender,
      }),
    );
  }
}
