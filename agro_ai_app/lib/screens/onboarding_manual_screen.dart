import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_ai_app/localization.dart';
import 'home_screen.dart';

class OnboardingManualScreen extends StatefulWidget {
  const OnboardingManualScreen({super.key});

  @override
  State<OnboardingManualScreen> createState() => _OnboardingManualScreenState();
}

class _OnboardingManualScreenState extends State<OnboardingManualScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> get _onboardingData => [
    {
      "image": "assets/images/ob_1.png",
      "title": Lang.t("ob1_title"),
      "text": Lang.t("ob1_text"),
    },
    {
      "image": "assets/images/ob_2.png",
      "title": Lang.t("ob2_title"),
      "text": Lang.t("ob2_text"),
    },
    {
      "image": "assets/images/ob_3.png",
      "title": Lang.t("ob3_title"),
      "text": Lang.t("ob3_text"),
    },
    {
      "image": "assets/images/ob_4.png",
      "title": Lang.t("ob4_title"),
      "text": Lang.t("ob4_text"),
    },
    {
      "image": "assets/images/ob_5.png",
      "title": Lang.t("ob5_title"),
      "text": Lang.t("ob5_text"),
    },
    {
      "image": "assets/images/ob_6.png",
      "title": Lang.t("ob6_title"),
      "text": Lang.t("ob6_text"),
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
    final data = _onboardingData;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: data.length,
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
                                image: AssetImage(data[index]["image"]!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          data[index]["title"]!,
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
                          data[index]["text"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (index < data.length - 1)
                          InkWell(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500), 
                                curve: Curves.easeInOut
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(Lang.t("swipe_hint"), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.green.shade600),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 40), // Maintain spacing on last page
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
                      data.length,
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
                    crossFadeState: _currentPage == data.length - 1
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
                      child: Text(Lang.t("get_started"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    secondChild: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: Text(Lang.t("skip"), style: const TextStyle(fontSize: 16)),
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
