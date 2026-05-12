import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'onboarding_manual_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'country_selection_screen.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:agro_ai_app/localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthState { checkPhone, login, signup, forgotPassword, signupOtp, forgotPasswordOtp }

class _LoginScreenState extends State<LoginScreen> {
  AuthState _currentFlow = AuthState.checkPhone;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ConfirmationResult? _confirmationResult; // Only for Web Auth Flow


  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _selectedCountryCode = "+91";
  String _deliveryMethod = "sms";
  String _userNameIfKnown = "";
  Map<String, dynamic>? _foundUserData;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Lang().addListener(_onLangChanged);
  }

  void _onLangChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    Lang().removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenManual = prefs.getBool('hasSeenManual') ?? false;
    String? userCountry = prefs.getString('user_country');
    
    if (!mounted) return;
    
    // 1. If country is not set, go to CountrySelectionScreen first
    if (userCountry == null) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CountrySelectionScreen()));
       return;
    }

    // 2. If country is set but manual not seen, go to Manual
    if (!hasSeenManual) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingManualScreen()));
       return;
    }

    // 3. Otherwise, go home
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }

  // Google Sign In Logic
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      
      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', account.displayName ?? "Google User");
        await prefs.setString('userPhone', account.email); // Using email as identifier
        
        _showSnackbar("Logged in as ${account.displayName}", Colors.green);
        
        // --- SAVE TO FIREBASE ---
        await FirebaseService.saveUser(account.email, account.displayName ?? "Google User");
        
        _checkOnboardingAndNavigate();
      }
    } catch (error) {
      _showSnackbar("Google Sign-In failed: $error", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 1. Check if user exists in Firestore and Trigger Firebase OTP
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
      // Step A: Check if user exists in Firestore instead of Uvicorn
      final userData = await FirebaseService.checkUser(fullPhone);
      
      if (kIsWeb) {
         // Step B: Firebase Phone Auth for Web
         _confirmationResult = await _auth.signInWithPhoneNumber(fullPhone);
         if (userData != null) {
            setState(() {
              _foundUserData = userData;
              _userNameIfKnown = userData['name'] ?? "User";
              _currentFlow = AuthState.login; // Proceed with password
            });
         } else {
            setState(() => _currentFlow = AuthState.signup);
         }
      } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)) {
         // DESKTOP BYPASS: Simulate sending OTP
         _showSnackbar("Desktop Mode: Skipping Firebase OTP. Enter '123456' as OTP.", Colors.blue);
         if (userData != null) {
            setState(() {
              _foundUserData = userData;
              _userNameIfKnown = userData['name'] ?? "User";
              _currentFlow = AuthState.login; // Proceed with password
            });
         } else {
            setState(() => _currentFlow = AuthState.signup);
         }
      } else {
         // Step B: Mobile Auth - Requires verifyPhoneNumber
         // [Placeholder for Mobile implementation if needed]
         _showSnackbar("This version is optimized for Web.", Colors.orange);
      }
    } catch (e) {
      _showSnackbar("Firebase Auth error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Existing User Login - Now using OTP instead of custom password
  // (Or you can keep custom password but use Firebase for persistence)
  Future<void> _login() async {
    final enteredPassword = _passwordController.text.trim();
    final storedPassword = _foundUserData?['password'] ?? "";

    if (enteredPassword.isEmpty) {
      _showSnackbar("Please enter your password", Colors.red);
      return;
    }

    if (enteredPassword == storedPassword) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userNameIfKnown);
        await prefs.setString('userPhone', "$_selectedCountryCode${_phoneController.text.trim()}");
        
        _showSnackbar("Login Successful!", Colors.green);
        _checkOnboardingAndNavigate();
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showSnackbar("Incorrect password. Please try again or use 'Forgot Password'.", Colors.red);
    }
  }

  // 3. Request OTP - Re-implemented for Firebase
  Future<void> _requestOtp(AuthState nextState) async {
    final name = _nameController.text.trim();
    if (nextState == AuthState.signupOtp && _currentFlow == AuthState.signup && name.isEmpty) {
      _showSnackbar("Please enter a name", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode${_phoneController.text.trim()}";

    try {
      if (kIsWeb) {
         if (_confirmationResult != null) {
            setState(() => _currentFlow = nextState);
            _showSnackbar("Code sent via Firebase", Colors.green);
         } else {
            _confirmationResult = await _auth.signInWithPhoneNumber(fullPhone);
            setState(() => _currentFlow = nextState);
         }
      } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)) {
         // Desktop Bypass
         setState(() => _currentFlow = nextState);
         _showSnackbar("Desktop Mode: Enter '123456' to verify.", Colors.blue);
      } else {
         setState(() => _currentFlow = nextState);
      }
    } catch (e) {
      _showSnackbar("Failed to send OTP via Firebase: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. Verify OTP using Firebase Result
  Future<void> _verifyOtpAndSave() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _confirmationResult == null) return;
    
    setState(() => _isLoading = true);
    final fullPhone = "$_selectedCountryCode${_phoneController.text.trim()}";
    
    try {
      bool isVerified = false;

      if (kIsWeb) {
         final UserCredential userCredential = await _confirmationResult!.confirm(otp);
         isVerified = userCredential.user != null;
      } else if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)) {
         // Desktop bypass validation
         if (otp == "123456") {
           isVerified = true;
         } else {
           throw Exception("Please enter 123456 for Desktop testing.");
         }
      }

      if (isVerified) {
         if (mounted) {
            final prefs = await SharedPreferences.getInstance();
            final nameToSave = _currentFlow == AuthState.signupOtp 
                ? _nameController.text 
                : _userNameIfKnown;
                
            await prefs.setString('userName', nameToSave);
            await prefs.setString('userPhone', fullPhone);

             // --- SAVE TO FIRESTORE ---
             await FirebaseService.saveUser(
               fullPhone, 
               nameToSave, 
               password: _passwordController.text.trim()
             );

            _checkOnboardingAndNavigate();
         }
      }
    } catch (e) {
      _showSnackbar("Invalid OTP verification: $e", Colors.red);
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
                  Image.asset('assets/images/logo.png', height: 180),
                  const SizedBox(height: 16),
                  Text(
                    Lang.t("title"),
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
        Text(Lang.t("enter_phone"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  decoration: InputDecoration(
                    hintText: Lang.t("phone_number_hint"),
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
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(Lang.t("next")),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(Lang.t("or"), style: const TextStyle(color: Colors.grey)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: Icon(Icons.email_outlined, color: Colors.red.shade500),
          label: Text(Lang.t("login_gmail"), style: const TextStyle(color: Colors.black87)),
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
        Text("${Lang.t("welcome_back")} ${_userNameIfKnown}!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("$_selectedCountryCode ${_phoneController.text}", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: Lang.t("password"),
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
            child: Text(Lang.t("forgot_pwd"), style: TextStyle(color: Colors.green.shade700)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(Lang.t("login_btn")),
        ),
        const SizedBox(height: 16),
         TextButton(
          onPressed: () => setState(() => _currentFlow = AuthState.checkPhone),
           child: Text(Lang.t("different_number")),
         )
      ],
    );
  }

  Widget _buildRegisterOrForgotDetailsScreen() {
    bool isForgot = _currentFlow == AuthState.forgotPassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isForgot ? Lang.t("reset_details") : Lang.t("register_profile"), 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: Lang.t("full_name"),
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
            labelText: isForgot ? Lang.t("new_password") : Lang.t("create_password"),
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
         Text(Lang.t("receive_otp_via"), style: const TextStyle(fontWeight: FontWeight.bold)),
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
