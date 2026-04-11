import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/weather_service.dart';
import 'disease_alert_map.dart';

class AiAlertsScreen extends StatefulWidget {
  const AiAlertsScreen({super.key});

  @override
  State<AiAlertsScreen> createState() => _AiAlertsScreenState();
}

class _AiAlertsScreenState extends State<AiAlertsScreen> {
  bool _isLoading = true;
  List<dynamic>? _forecast;
  String _predictedDisease = "Searching...";
  String _riskLevel = "Low";
  String _preRemedies = "Loading recommendations...";
  String _pesticides = "Loading products...";
  String _avoidance = "Loading tips...";

  @override
  void initState() {
    super.initState();
    _loadAiPredictions();
  }

  Future<void> _loadAiPredictions() async {
    setState(() => _isLoading = true);
    
    // In a real app, we'd fetch actual 3-day forecast
    // For now, we simulate AI analysis based on current weather
    final weather = await WeatherService.getWeatherAuto();
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _forecast = [
          {"day": "Tomorrow", "temp": "29°C", "condition": "Humid"},
          {"day": "Day 2", "temp": "31°C", "condition": "Rainy"},
          {"day": "Day 3", "temp": "28°C", "condition": "Stormy"},
        ];
        
        // Mock AI Prediction Logic based on humidity/rain
        _predictedDisease = "Leaf Blight & Fungal Infection";
        _riskLevel = "HIGH ALERT";
        _preRemedies = "Reduce irrigation immediately. Ensure proper drainage in the field to avoid waterlogging.";
        _pesticides = "Mancozeb 75% WP or Carbendazim 50% WP (1g per liter or as directed).";
        _avoidance = "Avoid nitrogen-rich fertilizers during high humidity. Space crops for better airflow.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(Lang.t("ai_alerts")),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMapCard(),
                const SizedBox(height: 20),
                _buildWeatherSection(),
                const SizedBox(height: 24),
                _buildPredictionCard(),
                const SizedBox(height: 24),
                _buildDetailSection("Remedies & Prevention", _preRemedies, Icons.health_and_safety, Colors.greenAccent),
                const SizedBox(height: 16),
                _buildDetailSection("Recommended Pesticides", _pesticides, Icons.bug_report, Colors.orangeAccent),
                const SizedBox(height: 16),
                _buildDetailSection("How to Avoid", _avoidance, Icons.shield, Colors.blueAccent),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text("3-Day Forecast Forecast", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _forecast!.map((f) => Column(
              children: [
                Text(f['day'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                const Icon(Icons.wb_cloudy, color: Colors.blueAccent, size: 24),
                const SizedBox(height: 8),
                Text(f['temp'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(f['condition'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade900, Colors.black]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
            child: Text(_riskLevel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text("AI PREDICTION", style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_predictedDisease, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            "Based on high humidity (85%) and predicted rainfall tomorrow, the environmental index for fungal growth has spiked.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiseaseAlertMapScreen())),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: const DecorationImage(
            image: NetworkImage("https://images.unsplash.com/photo-1526778545894-62b44c912707?auto=format&fit=crop&q=80&w=1000"),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
          border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.map_outlined, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("REGIONAL OUTBREAK MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Live Disease Tracking • Rajanukunte", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
