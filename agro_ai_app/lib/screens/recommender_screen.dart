import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:agro_ai_app/service/gemini_service.dart';
import 'package:agro_ai_app/service/weather_service.dart';
import 'package:agro_ai_app/localization.dart';

class RecommenderScreen extends StatefulWidget {
  const RecommenderScreen({super.key});

  @override
  State<RecommenderScreen> createState() => _RecommenderScreenState();
}

class _RecommenderScreenState extends State<RecommenderScreen> {
  final TextEditingController _soilController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _getRecommendation() async {
    if (_soilController.text.isEmpty || _seasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final weather = await WeatherService.getWeatherAuto();
      final temp = weather['main']?['temp'] ?? "unknown";
      final loc = weather['name'] ?? "unknown";

      final prompt = '''
      Act as an expert agricultural scientist. 
      The farmer is in $loc with a current temperature of $temp°C. 
      Their soil type is "${_soilController.text}". 
      The upcoming season is "${_seasonController.text}". 
      
      Based on this data, recommend the top 3 best crops for them to plant for maximum yield and profit. 
      Provide a brief reason why for each, and 1 tip for soil preparation.
      Use clear markdown formatting.
      ''';

      final geminiService = GeminiService();
      final response = await geminiService.askGemini(prompt, languageCode: Lang.lang);

      setState(() {
        _result = response;
      });
    } catch (e) {
      setState(() {
        _result = "Failed to get recommendation. Please check your connection. Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("AI Crop Recommender", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.psychology, size: 48, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text("Plan Your Next Harvest", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Tell us about your farm, and our AI will recommend the most profitable crops.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _soilController,
                    decoration: InputDecoration(
                      labelText: "Soil Type (e.g., Red, Black, Sandy, Loamy)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.landscape),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _seasonController,
                    decoration: InputDecoration(
                      labelText: "Upcoming Season (e.g., Kharif, Rabi, Summer)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.wb_sunny),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _getRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Get AI Recommendation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: MarkdownBody(data: _result!),
              ),
          ],
        ),
      ),
    );
  }
}
