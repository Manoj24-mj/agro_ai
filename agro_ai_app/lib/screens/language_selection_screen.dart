import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<Map<String, String>> _allLanguages = [
    {"name": "English", "code": "en", "native": "English", "flag": "🇺🇸"},
    {"name": "Kannada", "code": "kn", "native": "ಕನ್ನಡ", "flag": "🇮🇳"},
    {"name": "Hindi", "code": "hi", "native": "हिंदी", "flag": "🇮🇳"},
    {"name": "Telugu", "code": "te", "native": "తెలుగు", "flag": "🇮🇳"},
    {"name": "Tamil", "code": "ta", "native": "தமிழ்", "flag": "🇮🇳"},
    {"name": "Marathi", "code": "mr", "native": "मराठी", "flag": "🇮🇳"},
    {"name": "Bengali", "code": "bn", "native": "বাংলা", "flag": "🇮🇳"},
    {"name": "Gujarati", "code": "gu", "native": "ગુજરાતી", "flag": "🇮🇳"},
    {"name": "Malayalam", "code": "ml", "native": "മലയാളം", "flag": "🇮🇳"},
    {"name": "Punjabi", "code": "pa", "native": "ਪੰਜਾਬੀ", "flag": "🇮🇳"},
  ];

  List<Map<String, String>> _filteredLanguages = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _allLanguages;
    _searchController.addListener(_filterLanguages);
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLanguages = _allLanguages.where((l) {
        return l["name"]!.toLowerCase().contains(query) || 
               l["native"]!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(Lang.t("select_language_title")),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: Lang.t("search_language_hint"),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: _filteredLanguages.isEmpty
              ? Center(child: Text(Lang.t("no_language_found")))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _filteredLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = _filteredLanguages[index];
                    final isSelected = Lang.lang == lang["code"];
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.green[300]! : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () async {
                          Lang().setLang(lang["code"]!);
                          setState(() {}); // Refresh local UI
                          
                          // Proceed to login after a short delay
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(lang["flag"]!, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          lang["native"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green[900] : Colors.black87,
                          ),
                        ),
                        subtitle: Text(lang["name"]!),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: Colors.green) 
                          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
