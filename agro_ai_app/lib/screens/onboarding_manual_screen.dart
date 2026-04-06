import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingManualScreen extends StatefulWidget {
  const OnboardingManualScreen({super.key});

  @override
  State<OnboardingManualScreen> createState() => _OnboardingManualScreenState();
}

class _OnboardingManualScreenState extends State<OnboardingManualScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/ob_1.png",
      "title": "Problem Identification",
      "text": "\"My crops are dying... I don’t know what’s wrong!\"\n\nObserve: yellowing leaves, spots, wilting",
    },
    {
      "image": "assets/images/ob_2.png",
      "title": "Capture Crop Image",
      "text": "\"Take a clear photo of the affected leaf.\"\n\nUse good lighting and focus",
    },
    {
      "image": "assets/images/ob_3.png",
      "title": "Scan Leaf",
      "text": "\"Scan the leaf using the app.\"\n\nUpload and wait for AI processing",
    },
    {
      "image": "assets/images/ob_4.png",
      "title": "Detection Result",
      "text": "\"Disease Detected: Leaf Blight\"\n\"Treatment: Use Fungicide Spray\"\n\n💡 Remember to give sun & water",
    },
    {
      "image": "assets/images/ob_5.png",
      "title": "Improvement",
      "text": "\"My crops are healthy now!\"\n\nFollow advice and monitor regularly",
    },
    {
      "image": "assets/images/ob_6.png",
      "title": "Successful Harvest",
      "text": "\"Good job, Kisan! Great harvest!\"\n\nHealthy crops, better yield, confidence",
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenManual', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const HomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                )
                              ],
                              image: DecorationImage(
                                image: AssetImage(onboardingData[index]["image"]!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          onboardingData[index]["title"]!,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]["text"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (index < onboardingData.length - 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Swipe", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.green.shade600),
                            ],
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Pagination & Button Area
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.green.shade600 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _currentPage == onboardingData.length - 1
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    secondChild: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text("Skip", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
