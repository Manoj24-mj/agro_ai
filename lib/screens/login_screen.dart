import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'onboarding_manual_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthState { checkPhone, login, signup, forgotPassword, signupOtp, forgotPasswordOtp }

class _LoginScreenState extends State<LoginScreen> {
  AuthState _currentFlow = AuthState.checkPhone;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _selectedCountryCode = "+91";
  String _deliveryMethod = "sms";
  String _userNameIfKnown = "";
  bool _obscurePassword = true;

  Future<void> _checkOnboardingAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenManual = prefs.getBool('hasSeenManual') ?? false;
    
    if (!mounted) return;
    
    if (hasSeenManual) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingManualScreen()));
    }
  }

  // 1. Check if user exists
  Future<void> _processPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showSnackbar("Error: Only numbers are allowed in the phone number.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode$phone";

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/check-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true) {
          setState(() {
            _userNameIfKnown = data['name'];
            _currentFlow = AuthState.login;
          });
        } else {
          setState(() => _currentFlow = AuthState.signup);
        }
      } else {
        _showSnackbar("Error: Server returned ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Network error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Existing User Password Login
  Future<void> _login() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode${_phoneController.text.trim()}";

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone, 'password': password}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _checkOnboardingAndNavigate();
        }
      } else {
        _showSnackbar("Incorrect Password!", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Network error", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. Request OTP
  Future<void> _requestOtp(AuthState nextState) async {
    final name = _nameController.text.trim();
    if (nextState == AuthState.signupOtp && name.isEmpty) {
      _showSnackbar("Please enter a name", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode${_phoneController.text.trim()}";

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone, 'method': _deliveryMethod}),
      );

      if (response.statusCode == 200) {
        setState(() => _currentFlow = nextState);
        _showSnackbar("OTP Sent to Your Phone", Colors.green);
      } else {
         _showSnackbar("Failed to send OTP", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Network error", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. Verify OTP and Write Details
  Future<void> _verifyOtpAndSave() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;
    
    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode${_phoneController.text.trim()}";
    
    String endpoint = _currentFlow == AuthState.signupOtp ? '/register' : '/reset-password';
    
    Map<String, dynamic> body = {
      'phone': fullPhone,
      'otp': otp,
    };

    if (_currentFlow == AuthState.signupOtp) {
      body['name'] = _nameController.text;
      body['password'] = _passwordController.text;
    } else {
      // Forgot Password route
      body['new_name'] = _nameController.text;
      body['new_password'] = _passwordController.text;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
           _checkOnboardingAndNavigate();
        }
      } else {
        _showSnackbar("Invalid OTP!", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Network error", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showSnackbar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.eco, size: 80, color: Colors.green.shade600),
                  const SizedBox(height: 16),
                  Text(
                    "Agro AI Doctor",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 48),

                  _buildDynamicForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicForm() {
    switch (_currentFlow) {
      case AuthState.checkPhone:
        return _buildCheckPhoneScreen();
      case AuthState.login:
        return _buildLoginScreen();
      case AuthState.signup:
      case AuthState.forgotPassword:
        return _buildRegisterOrForgotDetailsScreen();
      case AuthState.signupOtp:
      case AuthState.forgotPasswordOtp:
        return _buildOtpVerificationScreen();
    }
  }

  Widget _buildCheckPhoneScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Enter Phone Number to Continue:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.phone, color: Colors.grey),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  style: const TextStyle(fontFamily: 'Roboto', color: Colors.black87, fontSize: 16),
                  onChanged: (v) => setState(() => _selectedCountryCode = v!),
                  items: const [
                    DropdownMenuItem(value: "+91", child: Text("🇮🇳 +91")),
                    DropdownMenuItem(value: "+1", child: Text("🇺🇸 +1")),
                    DropdownMenuItem(value: "+44", child: Text("🇬🇧 +44")),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: "Phone Number",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _processPhone,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Next"),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR", style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            // Simulate Google Login success
            _checkOnboardingAndNavigate();
          },
          icon: Icon(Icons.email_outlined, color: Colors.red.shade500),
          label: const Text("Login with Gmail", style: TextStyle(color: Colors.black87)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Welcome back, $_userNameIfKnown!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("$_selectedCountryCode ${_phoneController.text}", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              _nameController.clear();
              _passwordController.clear();
              setState(() => _currentFlow = AuthState.forgotPassword);
            },
            child: Text("Forgot Password?", style: TextStyle(color: Colors.green.shade700)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login"),
        ),
        const SizedBox(height: 16),
         TextButton(
          onPressed: () => setState(() => _currentFlow = AuthState.checkPhone),
           child: const Text("Use a different number"),
         )
      ],
    );
  }

  Widget _buildRegisterOrForgotDetailsScreen() {
    bool isForgot = _currentFlow == AuthState.forgotPassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isForgot ? "Reset Details & Password" : "Looks like you are new! Register Profile", 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: isForgot ? "New Password" : "Create Password",
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
         const Text("Receive OTP via:", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(child: RadioListTile<String>(title: const Text("SMS"), value: "sms", groupValue: _deliveryMethod, onChanged: (v) => setState(() => _deliveryMethod = v!), activeColor: Colors.green)),
            Expanded(child: RadioListTile<String>(title: const Text("WhatsApp"), value: "whatsapp", groupValue: _deliveryMethod, onChanged: (v) => setState(() => _deliveryMethod = v!), activeColor: Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _requestOtp(isForgot ? AuthState.forgotPasswordOtp : AuthState.signupOtp),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Get OTP to Verify"),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _currentFlow = AuthState.checkPhone),
          child: const Text("Go Back"),
        )
      ],
    );
  }

  Widget _buildOtpVerificationScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Enter the OTP sent to\n$_selectedCountryCode ${_phoneController.text}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "000000",
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtpAndSave,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Verify & Save Profile"),
        ),
      ],
    );
  }
}
