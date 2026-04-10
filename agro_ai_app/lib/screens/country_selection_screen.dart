import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/location_service.dart';
import 'home_screen.dart';
import 'onboarding_manual_screen.dart';
import 'package:agro_ai_app/localization.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  String? _selectedCountry;
  String? _detectedCity;
  bool _isDetecting = false;
  
  final List<String> _countries = [
    "India", "United States", "Brazil", "China", "Australia", 
    "Germany", "France", "United Kingdom", "Nigeria", "South Africa"
  ];

  @override
  void initState() {
    super.initState();
    _autoDetectLocation();
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetecting = true);
    final location = await LocationService.getCurrentLocation();
    if (location != null && mounted) {
      final country = location['country'];
      if (country != null && !_countries.contains(country)) {
        _countries.add(country);
      }
      setState(() {
        if (_selectedCountry == null) {
          _selectedCountry = country;
        }
        _detectedCity = location['city'];
        _isDetecting = false;
      });
      _showSnackbar("Detected: $_detectedCity, $country");
    } else if (mounted) {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedCountry == null) {
      _showSnackbar("Please select a country first");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_new_user', false);
    await prefs.setString('user_country', _selectedCountry!);
    if (_detectedCity != null) {
      await prefs.setString('user_city', _detectedCity!);
    }

    if (mounted) {
      bool hasSeenManual = prefs.getBool('hasSeenManual') ?? false;
      if (hasSeenManual) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingManualScreen()));
      }
    }
  }

  void _showSnackbar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/logo.png', height: 180),
              const SizedBox(height: 16),
              Text(
                Lang.t("welcome_title"),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                Lang.t("country_select_msg"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    hint: const Text("Select your country"),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
                    items: _countries.map((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      setState(() {
                        _selectedCountry = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isDetecting)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
                      const SizedBox(width: 12),
                      Text(Lang.t("detecting_loc"), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _autoDetectLocation,
                  icon: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
                  label: const Text("Refetch Location", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ),
              if (_detectedCity != null && !_isDetecting)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    "${Lang.t("detected_city")} $_detectedCity",
                    style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: Text(Lang.t("continue_btn"), style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
