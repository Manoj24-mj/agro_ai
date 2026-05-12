import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/weather_service.dart';
import 'package:agro_ai_app/service/voice_service.dart';
import 'package:agro_ai_app/widgets/searchable_picker.dart';
import 'chatbot_screen.dart';
import 'detector_screen.dart';
import 'saved_screen.dart';
import 'history_screen.dart';
import 'community_screen.dart';
import 'market_screen.dart';
import 'calculator_screen.dart'; 
import 'crop_price_screen.dart'; 
import 'user_activity_screen.dart'; 
import 'crops_module_screen.dart';
import 'disease_alert_screen.dart';
import 'tips_screen.dart';
import 'analytics_screen.dart'; 
import 'monitoring_screen.dart';
import 'ai_alerts_screen.dart';
import 'schemes_screen.dart';
import 'recommender_screen.dart';
import 'ledger_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  late AnimationController _vortexController;
  late Animation<double> _vortexRotation;
  bool _isLoadingWeather = false;
  final TextEditingController _cityController = TextEditingController();
  
  int _bottomNavIndex = 0;
  bool _darkMode = false;
  String userName = "Smart Kisan User";
  String userPhone = "+91 9876543210";
  String farmSpecs = "Wheat & Corn • 15 Acres • Expert";
  dynamic _profileImage; // Using dynamic to avoid File vs XFile issues on web
  DateTime? _lastRefreshTime;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _vortexController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _vortexRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(CurvedAnimation(parent: _vortexController, curve: Curves.linear));
    // Listen for language changes and rebuild the home screen immediately
    Lang().addListener(_onLangChanged);
    Future.delayed(const Duration(milliseconds: 500), () => _fetchWeatherAuto());
  }

  void _onLangChanged() => setState(() {});

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Smart Kisan User";
      userPhone = prefs.getString('userPhone') ?? "+91 9876543210";
      farmSpecs = prefs.getString('farmSpecs') ?? "Wheat & Corn • 15 Acres • Expert";
    });
  }



  Future<void> _fetchWeatherAuto({bool forceRefresh = false}) async {
    // 5-second cooldown for refresh button to protect API limits
    if (forceRefresh && _lastRefreshTime != null && 
        DateTime.now().difference(_lastRefreshTime!) < const Duration(seconds: 5)) {
      return; 
    }
    
    setState(() => _isLoadingWeather = true);
    if (forceRefresh) _lastRefreshTime = DateTime.now();
    
    final data = await WeatherService.getWeatherAuto(forceRefresh: forceRefresh);
    setState(() {
      _weatherData = data;
      _isLoadingWeather = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Lang.t("good_morning");
    if (hour >= 12 && hour < 17) return Lang.t("good_afternoon");
    if (hour >= 17 && hour < 21) return Lang.t("good_evening");
    return Lang.t("good_night");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: _bottomNavIndex == 0 
        ? AppBar(
            title: Text(Lang.t("title")),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(VoiceService.isMaleVoice ? Icons.face : Icons.face_3),
                tooltip: "Switch Voice Gender",
                onPressed: () {
                  setState(() => VoiceService.isMaleVoice = !VoiceService.isMaleVoice);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(VoiceService.isMaleVoice ? Lang.t("voice_male") : Lang.t("voice_female"))));
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                onSelected: (l) => setState(() => Lang().setLang(l)),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: "en", child: Text("English")),
                  PopupMenuItem(value: "kn", child: Text("ಕನ್ನಡ")),
                  PopupMenuItem(value: "hi", child: Text("हिंदी")),
                ],
              ),
            ],
          )
        : null,
      drawer: _bottomNavIndex == 0 ? _buildDrawer() : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        backgroundColor: _darkMode ? Colors.grey[850] : Colors.white,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: Lang.t("home_tab")),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: Lang.t("community_btn")), // Community
          BottomNavigationBarItem(icon: const Icon(Icons.store), label: Lang.t("market_btn")), // Market
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: Lang.t("profile_tab")),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_bottomNavIndex == 1) return const CommunityScreen();
    if (_bottomNavIndex == 2) return const MarketScreen();
    if (_bottomNavIndex == 3) return _buildProfileScreen();
    return _buildHomeContent();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          Container(
            color: Colors.green.shade100,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco, size: 48, color: Colors.green.shade800),
                const SizedBox(height: 10),
                Text(Lang.t("title"), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.settings, color: _darkMode ? Colors.white70 : Colors.grey[700]), 
                  title: Text(Lang.t("settings"), style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                  onTap: () {
                    Navigator.pop(context); 
                    _showSettingsDialog();
                  },
                ),
                ListTile(leading: Icon(Icons.feedback, color: _darkMode ? Colors.white70 : Colors.grey[700]), title: Text(Lang.t("feedback"), style: TextStyle(color: _darkMode ? Colors.white : Colors.black))),
                ListTile(leading: Icon(Icons.share, color: _darkMode ? Colors.white70 : Colors.grey[700]), title: Text(Lang.t("share"), style: TextStyle(color: _darkMode ? Colors.white : Colors.black))),
                ListTile(leading: Icon(Icons.contact_mail, color: _darkMode ? Colors.white70 : Colors.grey[700]), title: Text(Lang.t("contact"), style: TextStyle(color: _darkMode ? Colors.white : Colors.black))),
                ListTile(leading: Icon(Icons.favorite, color: Colors.red.shade400), title: Text(Lang.t("thanks"), style: TextStyle(color: _darkMode ? Colors.white : Colors.black))),
                ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text(Lang.t("logout")), onTap: () => Navigator.of(context).pushReplacementNamed('/')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.science, size: 50, color: Colors.green.shade200),
          )
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(Lang.t("settings")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(Lang.t("dark_mode")),
                value: _darkMode,
                onChanged: (v) {
                  setDialogState(() => _darkMode = v);
                  setState(() => _darkMode = v);
                },
              ),
              SwitchListTile(
                title: Text(Lang.t("cam_mic")),
                value: true,
                onChanged: (v) {},
              ),
              SwitchListTile(
                title: Text(Lang.t("notifications")),
                value: true,
                onChanged: (v) {},
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(Lang.t("close")))],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Lang.t("profile_tab"), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50, 
                    backgroundColor: Colors.green.shade100, 
                    backgroundImage: _profileImage != null 
                      ? (kIsWeb ? NetworkImage(_profileImage) : FileImage(io.File(_profileImage)) as ImageProvider)
                      : null,
                    child: _profileImage == null ? Icon(Icons.person, size: 60, color: Colors.green.shade800) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: MediaQuery.of(context).size.width / 2 - 50,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.camera_alt, color: Colors.teal, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: Text(Lang.t("name")),
              subtitle: Text(userName), 
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProfileField(Lang.t("name"), userName)),
            ),
            const Divider(),
            ListTile(
              title: Text(Lang.t("phone_number")),
              subtitle: Text(userPhone), 
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProfileField(Lang.t("phone_number"), userPhone)),
            ),
            const Divider(),
            ListTile(
              title: Text(Lang.t("farm_specs")),
              subtitle: Text(farmSpecs), 
              trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _editProfileField(Lang.t("farm_specs"), farmSpecs)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.post_add, color: Colors.teal),
              title: Text(Lang.t("my_posts")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => UserActivityScreen(
                    title: Lang.t("my_posts"), 
                    emptyMessage: Lang.t("empty_profile"),
                    items: [], // Mock data
                 )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.teal),
              title: Text(Lang.t("my_listings")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => UserActivityScreen(
                    title: Lang.t("my_listings"), 
                    emptyMessage: Lang.t("empty_listings"),
                    items: [], // Mock data
                 )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.teal),
              title: Text(Lang.t("usage_history")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const UsageHistoryScreen()));
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade800),
              child: Text(Lang.t("logout")),
            )
          ],
        ),
      ),
    );
  }

  void _editProfileField(String field, String currentValue) {
    // Determine if we are editing multi-part Farm Specs
    bool isFarmSpecs = field == Lang.t("farm_specs");
    
    // For Farm Specs, split the existing value into components for individual editing
    List<String> parts = currentValue.split(" • ");
    TextEditingController c1 = TextEditingController(text: isFarmSpecs && parts.isNotEmpty ? parts[0] : currentValue);
    TextEditingController c2 = TextEditingController(text: isFarmSpecs && parts.length > 1 ? parts[1] : "");
    TextEditingController c3 = TextEditingController(text: isFarmSpecs && parts.length > 2 ? parts[2] : "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${Lang.t("edit_title")} $field"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: isFarmSpecs 
              ? [
                  // Vertical inputs for Farm Specs components
                  TextField(controller: c1, decoration: InputDecoration(labelText: Lang.t("crop_label"), hintText: Lang.t("crop_hint"))),
                  const SizedBox(height: 12),
                  TextField(controller: c2, decoration: InputDecoration(labelText: Lang.t("land_size_label"), hintText: Lang.t("land_size_hint"))),
                  const SizedBox(height: 12),
                  TextField(controller: c3, decoration: InputDecoration(labelText: Lang.t("exp_level_label"), hintText: Lang.t("exp_level_hint"))),
                ]
              : [
                  // Standard vertical input for singular fields
                  TextField(
                    controller: c1,
                    decoration: InputDecoration(hintText: "${Lang.t("enter_new")} $field"),
                  ),
                ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  // Robust localization-aware field updates
                  if (field == Lang.t("name")) {
                    userName = c1.text;
                    prefs.setString('userName', userName);
                  }
                  if (field == Lang.t("phone_number")) {
                    userPhone = c1.text;
                    prefs.setString('userPhone', userPhone);
                  }
                  if (isFarmSpecs) {
                    // Re-package vertical inputs back into formatted summary string
                    farmSpecs = "${c1.text} • ${c2.text} • ${c3.text}";
                    prefs.setString('farmSpecs', farmSpecs);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      }
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: _darkMode ? Colors.white : Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _WeatherCard(
              weather: _weatherData,
              isLoading: _isLoadingWeather,
              onRefresh: () => _fetchWeatherAuto(forceRefresh: true),
            ),
            const SizedBox(height: 30),
            
            // 1. AI Command Center Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.psychology_outlined, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Lang.t("ai_command_center"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 1. Core Action Vortex
            AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.shade800,
                        Colors.blueGrey.shade700,
                        Colors.green.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_vortexRotation.value),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("detector_btn"),
                              icon: Icons.camera_alt_outlined,
                              color: Colors.greenAccent.shade100,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DetectorScreen())),
                              pulseValue: _vortexRotation.value,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("history_btn"),
                              icon: Icons.history,
                              color: Colors.purpleAccent.shade100,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UsageHistoryScreen())),
                              pulseValue: _vortexRotation.value + 0.5,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("saved_btn"),
                              icon: Icons.bookmark_border,
                              color: Colors.blueAccent.shade100,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedScreen())),
                              pulseValue: _vortexRotation.value + 1.0,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("chat_btn"),
                              icon: Icons.auto_awesome,
                              color: Colors.amberAccent.shade100,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen())),
                              pulseValue: _vortexRotation.value + 1.5,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("monitoring_btn"),
                              icon: Icons.monitor_heart_outlined,
                              color: Colors.cyanAccent.shade100,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitoringScreen())),
                              pulseValue: _vortexRotation.value + 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
            
            const SizedBox(height: 24),
            
            // 2. Smart Kisan Tools Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.terminal_outlined, color: Colors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Lang.t("smart_tools"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 2. Separate Layout for Calculators Box
            AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade800,
                        Colors.blueGrey.shade600,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                       ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildDashboardButton(
                                  context: context,
                                  title: Lang.t("fertilizer"),
                                  icon: Icons.science_outlined,
                                  color: Colors.orangeAccent.shade100,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen(type: "Fertilizer"))),
                                  pulseValue: _vortexRotation.value,
                                ),
                                _buildDashboardButton(
                                  context: context,
                                  title: Lang.t("pesticide"),
                                  icon: Icons.pest_control,
                                  color: Colors.redAccent.shade100,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen(type: "Pesticide"))),
                                  pulseValue: _vortexRotation.value + 0.5,
                                ),
                                _buildDashboardButton(
                                  context: context,
                                  title: Lang.t("farming"),
                                  icon: Icons.agriculture,
                                  color: Colors.lightGreenAccent.shade100,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen(type: "Farming"))),
                                  pulseValue: _vortexRotation.value + 1.0,
                                ),
                                _buildDashboardButton(
                                  context: context,
                                  title: Lang.t("crop_price"),
                                  icon: Icons.currency_exchange,
                                  color: Colors.greenAccent.shade100,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropPriceScreen())),
                                  pulseValue: _vortexRotation.value + 1.5,
                                ),
                                _buildDashboardButton(
                                  context: context,
                                  title: Lang.t("ai_alerts"),
                                  icon: Icons.notification_important_outlined,
                                  color: Colors.redAccent.shade100,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAlertsScreen())),
                                  pulseValue: _vortexRotation.value + 2.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
            
            const SizedBox(height: 24),

            // 3. Smart Agriculture Modules Logo & Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.settings_input_component_outlined, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Lang.t("control_panel"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Smart Modules Grid (Crops, Tips, Alerts, Analytics) 
            AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.shade900,
                        Colors.green.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("crops_db"),
                              icon: Icons.grass,
                              color: Colors.greenAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropsModuleScreen())),
                              pulseValue: _vortexRotation.value + 0.5,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("disease_alert"),
                              icon: Icons.notification_important,
                              color: Colors.redAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiseaseAlertScreen())),
                              pulseValue: _vortexRotation.value + 1.0,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("agro_tips"),
                              icon: Icons.lightbulb_outline,
                              color: Colors.yellowAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CultivationTipsScreen())),
                              pulseValue: _vortexRotation.value + 1.5,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: Lang.t("analytics"),
                              icon: Icons.analytics_outlined,
                              color: Colors.blueAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                              pulseValue: _vortexRotation.value + 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 30),
            // 5. Govt & Finance Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_outlined, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Govt & Finance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade800,
                        Colors.deepOrange.shade600,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDashboardButton(
                              context: context,
                              title: "Schemes",
                              icon: Icons.assured_workload,
                              color: Colors.yellowAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SchemesScreen())),
                              pulseValue: _vortexRotation.value + 0.5,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: "Crop AI",
                              icon: Icons.psychology,
                              color: Colors.lightGreenAccent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommenderScreen())),
                              pulseValue: _vortexRotation.value + 1.0,
                            ),
                            _buildDashboardButton(
                              context: context,
                              title: "Khata",
                              icon: Icons.account_balance_wallet,
                              color: Colors.white,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LedgerScreen())),
                              pulseValue: _vortexRotation.value + 1.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 30),
          ],
        ),
      );
  }

  Widget _buildDashboardButton({
    required BuildContext context, 
    required String title, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap, 
    required double pulseValue
  }) {
    double scale = 1.0 + 0.05 * (1.0 + (pulseValue.remainder(3.14159) - 1.5).abs());
    
    return GestureDetector(
      onTap: onTap,
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.0),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1),
                ]
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                title, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 10,
                  letterSpacing: 0.2,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatefulWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _WeatherCard({
    required this.weather,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> with SingleTickerProviderStateMixin {
  Timer? _debounce;
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  final List<String> _indianStates = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
    "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
  ];

  @override
  void initState() {
    super.initState();
    _indianStates.sort();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine));
    Lang().addListener(_onLangChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    Lang().removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    bool containsError = widget.weather?["error"] != null;
    String mainLoc = widget.weather?["name"] ?? "--";
    String stateLoc = widget.weather?["state"] ?? "";
    String fullLoc = stateLoc.isNotEmpty ? "$mainLoc, $stateLoc" : mainLoc;
    String cityName = containsError ? Lang.t("loc_error") : fullLoc;
    String temp = containsError ? "--" : (widget.weather?["main"]?["temp"]?.toString() ?? "--");
    
    // Simplify technical errors for users (especially 'Failed to fetch' on Web)
    String errorMsg = containsError ? widget.weather!["error"].toString() : "";
    if (errorMsg.contains("Failed to fetch") || errorMsg.contains("Network error")) {
       errorMsg = Lang.t("conn_lost");
    }
    
    String mainRaw = containsError ? errorMsg : (widget.weather?["weather"]?[0]?["main"] ?? "--");
    String main = containsError ? mainRaw : Lang.t(mainRaw);
    
    double wind = (widget.weather?["wind"]?["speed"] ?? 0.0).toDouble();
    int aqi = (widget.weather?["aqi"] ?? 0).toInt();
    double uvi = (widget.weather?["uvi"] ?? 0.0).toDouble();
    int pressure = (widget.weather?["main"]?["pressure"] ?? 0).toInt();
    int humidity = (widget.weather?["main"]?["humidity"] ?? 0).toInt();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 40, spreadRadius: -5),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // Expand Column to take space
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible( // Avoid long city name overflow
                                child: Text(
                                  cityName, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (!containsError) const Icon(Icons.my_location, size: 16, color: Colors.teal),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible( // Critical fix for overflow
                                child: Text(
                                  main, 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: containsError ? Colors.redAccent : Colors.teal[700], fontSize: 13, fontWeight: FontWeight.w600)
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.isLoading)
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal))
                    else
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.refresh, color: Colors.teal), onPressed: widget.onRefresh),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text("$temp°C", style: TextStyle(
                      fontSize: 64, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black.withOpacity(0.05), 
                    )),
                    Positioned(
                      top: -4,
                      left: -2,
                      child: Text("$temp°C", style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.teal.shade800)),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _WeatherTile(label: Lang.t("humidity_label"), value: "$humidity%", icon: Icons.water_drop, color: Colors.blueAccent),
                    _WeatherTile(label: Lang.t("wind_label"), value: "$wind km/h", icon: Icons.air, color: Colors.cyan),
                    _WeatherTile(label: Lang.t("uv_label"), value: "$uvi", icon: Icons.wb_sunny, color: _getUVColor(uvi)),
                    _WeatherTile(label: Lang.t("aqi_label"), value: _getAQILevel(aqi), icon: Icons.waves, color: _getAQIColor(aqi)),
                  ],
                ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedSearchField({required String hint, required IconData icon, required bool enabled, Widget? autocomplete, VoidCallback? onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withOpacity(0.6) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            if (enabled) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: autocomplete ?? Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: enabled ? Colors.teal : Colors.grey),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: enabled ? Colors.black87 : Colors.grey, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (enabled) const Icon(Icons.search, size: 18, color: Colors.teal),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUVColor(double uvi) {
    if (uvi < 3) return Colors.green;
    if (uvi < 6) return Colors.yellow[700]!;
    if (uvi < 8) return Colors.orange;
    if (uvi < 11) return Colors.red;
    return Colors.purple;
  }

  String _getAQILevel(int aqi) {
    if (aqi <= 50) return Lang.t("aqi_good");
    if (aqi <= 100) return Lang.t("aqi_fair");
    if (aqi <= 150) return Lang.t("aqi_moderate");
    if (aqi <= 200) return Lang.t("aqi_poor");
    return Lang.t("aqi_vpoor");
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }
}

class _WeatherTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WeatherTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.teal[800], fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}