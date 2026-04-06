import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/service/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class CultivationTipsScreen extends StatefulWidget {
  const CultivationTipsScreen({super.key});

  @override
  State<CultivationTipsScreen> createState() => _CultivationTipsScreenState();
}

class _CultivationTipsScreenState extends State<CultivationTipsScreen> with TickerProviderStateMixin {
  DateTime? _sowingDate;
  String? _cityName;
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = true;
  int _activeTab = 0; // 0: Smart Plan, 1: All Insights
  final Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? savedDate = prefs.getString('sowing_date');
      if (savedDate != null) _sowingDate = DateTime.parse(savedDate);
      _completedTaskIds.addAll(prefs.getStringList('completed_tasks') ?? []);
      _cityName = prefs.getString('manualCityName') ?? "Maharashtra";
    });
    
    // Fetch weather for dynamic triggers
    try {
      final data = await WeatherService.getWeatherManual(_cityName!);
      setState(() {
        _currentWeather = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setSowingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 120)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString('sowing_date', picked.toIso8601String());
       setState(() => _sowingDate = picked);
    }
  }

  Future<void> _toggleTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_completedTaskIds.contains(id)) _completedTaskIds.remove(id);
      else _completedTaskIds.add(id);
    });
    await prefs.setStringList('completed_tasks', _completedTaskIds.toList());
  }

  int get _cropAge => _sowingDate == null ? 0 : DateTime.now().difference(_sowingDate!).inDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text("🌾 Cultivation Planner", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _setSowingDate)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              // 1. Weather Alert Banner
              if (_currentWeather != null) _buildWeatherBanner(),

              // 2. Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _tabButton(0, "Smart Plan", Icons.auto_awesome),
                    const SizedBox(width: 12),
                    _tabButton(1, "Daily Tips", Icons.lightbulb_outline),
                  ],
                ),
              ),

              Expanded(
                child: _activeTab == 0 ? _buildSmartPlan() : _buildTipList(),
              ),
            ],
          ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    bool active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.green[800] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? Colors.green[800]! : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherBanner() {
    double temp = _currentWeather?['main']?['temp']?.toDouble() ?? 0.0;
    bool isHot = temp > 32;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHot ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHot ? Colors.orange.shade200 : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(isHot ? Icons.wb_sunny : Icons.cloud, color: isHot ? Colors.orange : Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Text("Weather Logic Alert ($temp°C)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               Text(isHot ? "Action: Increase Water Depth. High evaporation detected." : "Conditions stable for monitoring.", style: const TextStyle(fontSize: 12)),
          ]))
        ],
      ),
    );
  }

  Widget _buildSmartPlan() {
    if (_sowingDate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.calendar_month, size: 80, color: Colors.green.withOpacity(0.1)),
             const SizedBox(height: 20),
             const Text("No Smart Plan Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const Text("Set your sowing date to begin tracking.", style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 24),
             ElevatedButton.icon(onPressed: _setSowingDate, icon: const Icon(Icons.add), label: const Text("Set Sowing Date"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white)),
          ],
        ),
      );
    }

    final tasks = AgroDataService.fieldTasks;
    return Column(
       children: [
         // Progress Info
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text("RICE CROP AGE", style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                 Text("$_cropAge Days Old", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
               ]),
               Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.grass, color: Colors.green, size: 28)),
             ],
           ),
         ),
         const Divider(height: 30),
         Expanded(
           child: ListView.separated(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
             itemCount: tasks.length,
             separatorBuilder: (context, _) => const SizedBox(height: 16),
             itemBuilder: (context, i) {
                final t = tasks[i];
                bool isCurrent = _cropAge >= t['day_range'][0] && _cropAge <= t['day_range'][1];
                bool isDone = _completedTaskIds.contains(t['id']);
                return _buildTaskCard(t, isCurrent, isDone);
             },
           ),
         )
       ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isCurrent, bool isDone) {
    return Opacity(
      opacity: isCurrent || isDone ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: Colors.white, borderRadius: BorderRadius.circular(20),
           border: Border.all(color: isCurrent ? Colors.green : Colors.grey.shade200, width: isCurrent ? 2 : 1),
           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isCurrent ? Colors.orange : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: Text(isCurrent ? "DUE NOW" : "UPCOMING", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : Colors.grey))),
                const Spacer(),
                Checkbox(value: isDone, onChanged: (_) => _toggleTask(task['id']), activeColor: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Text(task['task'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(task['stage'], style: const TextStyle(fontSize: 10, color: Colors.blueGrey, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Text(task['description'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const Divider(height: 24),
            Row(children: [
               const Icon(Icons.info_outline, size: 14, color: Colors.blueAccent),
               const SizedBox(width: 8),
               Expanded(child: Text(task['weatherImpact'] ?? "Observe canopy for moisture.", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueAccent))),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildTipList() {
    final tips = AgroDataService.cultivationTips;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tips.length,
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final t = tips[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
             Icon(Icons.lightbulb_outline, color: Colors.orange),
             const SizedBox(width: 16),
             Expanded(child: Text(t['content'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
        );
      },
    );
  }
}
