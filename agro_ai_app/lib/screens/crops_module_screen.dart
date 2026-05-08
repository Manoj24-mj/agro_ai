import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/service/voice_service.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:agro_ai_app/screens/detector_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class CropsModuleScreen extends StatefulWidget {
  const CropsModuleScreen({super.key});

  @override
  State<CropsModuleScreen> createState() => _CropsModuleScreenState();
}

class _CropsModuleScreenState extends State<CropsModuleScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allCrops = [];
  List<Map<String, dynamic>> _recommendations = [];
  String? _state;
  String? _activeCategory; 
  String _selectedSeason = "All";
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    _allCrops = AgroDataService.getAllCrops();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _state = prefs.getString('manualCityName') ?? "Maharashtra";
      _recommendations = AgroDataService.getRecommendedCrops(_state);
    });
  }

  void _onSearch(String query) {
    setState(() {
      _currentQuery = query;
      if (query.isNotEmpty) {
        _activeCategory = "Search Results";
        _allCrops = AgroDataService.filterCrops(query: query, season: _selectedSeason);
      } else {
        _activeCategory = null;
      }
    });
  }

  Future<void> _onSearchSubmit(String query) async {
    if (query.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('userPhone');
      if (phone != null) {
        await FirebaseService.saveSearchHistory(
          phone: phone,
          query: query.trim(),
          category: "Crops Dictionary",
        );
      }
    }
  }

  void _selectCategory(String cat) {
    setState(() {
      _activeCategory = cat;
      _allCrops = AgroDataService.filterCrops(category: cat, season: _selectedSeason);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_activeCategory != null ? Lang.t(_activeCategory!) : Lang.t("browse_category"), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[800],
        elevation: 0,
        foregroundColor: Colors.white,
        leading: _activeCategory != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _activeCategory = null)) : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔍 SEARCH HEADER (WITH DYNAMIC INPUT DISPLAY)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(color: Colors.green[800], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    onSubmitted: _onSearchSubmit,
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.search, color: Colors.green),
                      hintText: Lang.t("search_hint_crops"),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  if (_currentQuery.isNotEmpty) 
                    Padding(
                       padding: const EdgeInsets.only(top: 10, left: 10),
                       child: Text("${Lang.t("searching_for")} \"$_currentQuery\"", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            if (_activeCategory == null) ...[
               _buildCategoryGrid(),
               _buildRecommendations(),
            ] else ...[
               _buildCropList(),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Lang.t("browse_category"), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130, // Compact cards on large screens
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: AgroDataService.cropCategories.length,
            itemBuilder: (context, i) {
              final cat = AgroDataService.cropCategories[i];
              return GestureDetector(
                onTap: () => _selectCategory(cat["name"]),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green[100]!)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat["icon"], style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(Lang.t(cat["name"]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [const Icon(Icons.auto_awesome, color: Colors.orange, size: 20), const SizedBox(width: 8), Text("${Lang.t("smart_reco")} $_state", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))]),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _recommendations.length,
            separatorBuilder: (context, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _buildWideCropCard(_recommendations[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCropList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Lang.t("found_crops").replaceFirst("{n}", _allCrops.length.toString()), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              DropdownButton<String>(
                value: _selectedSeason,
                items: ["All", "Kharif", "Rabi", "Zaid"].map((s) => DropdownMenuItem(value: s, child: Text(Lang.t(s), style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) {
                   setState(() {
                      _selectedSeason = v!;
                      _allCrops = AgroDataService.filterCrops(category: _activeCategory == "Search Results" ? null : _activeCategory, season: _selectedSeason);
                   });
                },
              )
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allCrops.length,
            separatorBuilder: (context, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) => _buildHorizontalCropItem(_allCrops[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCropCard(Map<String, dynamic> crop) {
    return GestureDetector(
      onTap: () => _openCropDetail(crop),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(image: AssetImage(crop["image"]), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
             Text(Lang.t(crop["name"]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             Text(Lang.t(crop["category"]), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildHorizontalCropItem(Map<String, dynamic> crop) {
     return GestureDetector(
       onTap: () => _openCropDetail(crop),
       child: Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
         child: Row(
           children: [
             ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(crop["image"], width: 80, height: 80, fit: BoxFit.cover)),
             const SizedBox(width: 16),
             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(Lang.t(crop["name"]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                 Text(crop["scientific_name"], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 8),
                 Row(children: [
                    Icon(Icons.calendar_today, size: 10, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(Lang.t(crop["cultivation"]["season"]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                 ]),
             ])),
             const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
           ],
         ),
       ),
     );
  }

  void _openCropDetail(Map<String, dynamic> crop) {
     Navigator.push(context, MaterialPageRoute(builder: (context) => CropDetailScreen(crop: crop)));
  }
}

// --- 🔥 COMPLETE CROP DETAIL SYSTEM UI ---
class CropDetailScreen extends StatefulWidget {
  final Map<String, dynamic> crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final VoiceService _voiceService = VoiceService();

  void _listenToSection(String title, String content) {
    _voiceService.speak("${Lang.t(title)}. $content");
  }

  void _listenToAll() {
    final c = widget.crop;
    String fullText = "Description for ${Lang.t(c['name'])}. Category: ${Lang.t(c['category'])}. Scientific Name: ${c['scientific_name']}. "
        "Growing conditions: Temperature ${c['growing_conditions']['temperature']}, Watering level ${c['growing_conditions']['watering']}. "
        "Soil requirement: ${c['soil']['type']}. "
        "NPK Fertilizer: Nitrogen ${c['fertilizer']['N']}, Phosphorus ${c['fertilizer']['P']}, Potassium ${c['fertilizer']['K']}. "
        "Expert tip: ${c['tips']}";
    _voiceService.speak(fullText);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.crop;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. Header Section
          SliverAppBar(
            expandedHeight: 300, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(c["image"], fit: BoxFit.cover),
              title: Text(Lang.t(c["name"]), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
            ),
            backgroundColor: Colors.green[800],
            actions: [
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => Share.share("Checkout agricultural data for ${Lang.t(c['name'])} on Smart Kisan!")),
            ],
          ),
          
          SliverList(
            delegate: SliverChildListDelegate([
              // 2. 🎧 Listen Feature
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Icon(Icons.headset_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(Lang.t("listen_full"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: _listenToAll, child: Text(Lang.t("listen_all"), style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),

              _buildSectionCard("🌤️ ${Lang.t("growing_cond")}", [
                _iconGridItem(Icons.wb_sunny, Lang.t("Temperature"), c['growing_conditions']['temperature']),
                _iconGridItem(Icons.light_mode, Lang.t("Sunlight"), c['growing_conditions']['sunlight']),
                _iconGridItem(Icons.water, Lang.t("Watering"), Lang.t(c['growing_conditions']['watering'])),
                _iconGridItem(Icons.cloud_outlined, Lang.t("Humidity"), c['growing_conditions']['humidity']),
              ], onListen: () => _listenToSection("growing_cond", "Temperature is ${c['growing_conditions']['temperature']} and Sunlight required is ${c['growing_conditions']['sunlight']}")),

              _buildSectionCard("🌱 ${Lang.t("soil_params")}", [
                 _lineItem(Lang.t("Type"), Lang.t(c['soil']['type'])),
                 _lineItem(Lang.t("pH Range"), c['soil']['ph']),
              ], onListen: () => _listenToSection("soil_params", "Required soil type is ${c['soil']['type']} with a pH of ${c['soil']['ph']}")),

              _buildSectionCard("📏 ${Lang.t("spacing_planting")}", [
                 _buildSpacingVisual(c['spacing']['row_to_row'], c['spacing']['plant_to_plant']),
                 const SizedBox(height: 12),
                 Text(c['spacing']['note'], style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ]),

              _buildSectionCard("🧪 ${Lang.t("fertilizer_npk")}", [
                 Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _npkDial("N", c['fertilizer']['N'], Colors.blue),
                    _npkDial("P", c['fertilizer']['P'], Colors.orange),
                    _npkDial("K", c['fertilizer']['K'], Colors.purple),
                 ]),
                 const SizedBox(height: 20),
                 SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calculate), label: Text(Lang.t("see_calc")))),
              ], onListen: () => _listenToSection("Fertilizer Requirements", "Nitrogen ${c['fertilizer']['N']}, Phosphorus ${c['fertilizer']['P']}, Potassium ${c['fertilizer']['K']} in ${c['fertilizer']['unit']}")),

              _buildSectionCard("🤝 ${Lang.t("crop_companions")}", [
                 _companionList("✅ Good Companions", c['companions']['good'], Colors.green),
                 const SizedBox(height: 16),
                 _companionList("❌ Avoid (Bad)", c['companions']['bad'], Colors.red),
                 const SizedBox(height: 12),
                 Text("💡 Why? ${c['companions']['explanation']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ]),

              _buildSectionCard("🌾 ${Lang.t("cultivation_info")}", [
                 _iconGridItem(Icons.history, Lang.t("life_cycle"), Lang.t(c['cultivation']['life_cycle'])),
                 _iconGridItem(Icons.grass, Lang.t("method"), Lang.t(c['cultivation']['method'])),
                 _iconGridItem(Icons.group, Lang.t("labour"), Lang.t(c['cultivation']['labour'])),
                 _iconGridItem(Icons.calendar_today, Lang.t("season"), Lang.t(c['cultivation']['season'])),
              ]),

              _buildSectionCard("🐛 ${Lang.t("pests_diseases_label")}", [
                 Wrap(spacing: 8, children: (c['pests_diseases'] as List).map((p) => Chip(label: Text(p), backgroundColor: Colors.red[50], side: BorderSide.none)).toList()),
                 const SizedBox(height: 12),
                 SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DetectorScreen())), icon: const Icon(Icons.science), label: Text(Lang.t("open_detector")), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white))),
              ]),

              _buildSectionCard("📍 ${Lang.t("region_suitability")}", [
                 Wrap(spacing: 8, children: (c['regions'] as List).map((r) => Chip(label: Text(r), backgroundColor: Colors.blue[50])).toList()),
              ]),

              const SizedBox(height: 100),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, {VoidCallback? onListen}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              if (onListen != null) IconButton(icon: const Icon(Icons.volume_up, size: 20, color: Colors.green), onPressed: onListen),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _iconGridItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [Icon(icon, color: Colors.green[800], size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))])]),
    );
  }

  Widget _lineItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(value)]),
    );
  }

  Widget _buildSpacingVisual(String row, String plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.grass, color: Colors.green),
            Container(width: 60, height: 2, color: Colors.brown[200]),
            const Icon(Icons.grass, color: Colors.green),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text("${Lang.t("Plant-to-Plant")}: $plant", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
          ),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
             Column(children: [const Icon(Icons.grass, color: Colors.green), Container(height: 20, width: 2, color: Colors.brown[200]), const Icon(Icons.grass, color: Colors.green)]),
             const SizedBox(width: 20),
             Text("${Lang.t("Row-to-Row")}: $row", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
          ])
        ],
      ),
    );
  }

  Widget _npkDial(String label, String val, Color color) {
    return Column(children: [
       Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18))),
       const SizedBox(height: 8),
       Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
       const Text("kg/acre", style: TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }

  Widget _companionList(String title, List<dynamic> items, Color color) {
     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: items.map((i) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Text(i, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)))).toList()),
     ]);
  }
}
