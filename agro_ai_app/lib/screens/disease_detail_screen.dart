import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/service/voice_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> disease;
  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _listenToDetails() {
    final d = widget.disease;
    String fullText = "Expert diagnosis for ${d['name']}. Symptoms: ${(d['symptoms'] as List).join('. ')}. "
        "Organic recommendation: Use ${d['organic_control']['agent']} with ${d['organic_control']['method']}. "
        "Chemical warning: ${d['chemical_control']['warning']}";
    _voiceService.speak(fullText);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.disease;
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 250, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
               background: Image.network(d["image"], fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset("assets/images/logo.png", fit: BoxFit.cover)),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => Share.share("AI Diagnosis for ${d['name']} detected. Treatment details inside Agro AI.")),
            ],
          ),
        ],
        body: Column(
          children: [
            // 🤖 AGENT ADVICE BOX
            _buildAgentBanner(),

            TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green[800],
              tabs: const [
                Tab(text: "Symptoms"),
                Tab(text: "Organic"),
                Tab(text: "Chemical"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSymptomTab(),
                  _buildOrganicTab(),
                  _buildChemicalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listenToDetails,
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.volume_up, color: Colors.white),
      ),
    );
  }

  Widget _buildAgentBanner() {
     return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green[200]!)),
        child: Row(
           children: [
              const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.psychology, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text("AGENT ADVICE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.green[800])),
                 const SizedBox(height: 4),
                 Text("MJ, I've detected ${widget.disease['name']}. Based on high regional humidity, I recommend organic treatment until the flowering stage.", style: const TextStyle(fontSize: 12, height: 1.4)),
              ])),
           ],
        ),
     );
  }

  Widget _buildSymptomTab() {
    final d = widget.disease;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text("Key Symptoms", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...(d["symptoms"] as List).map((s) => _bulletPoint(s)).toList(),
        const SizedBox(height: 32),
        Text("Preventative Measures", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...(d["prevention"] as List).map((p) => _bulletPoint(p, icon: Icons.shield_outlined)).toList(),
      ],
    );
  }

  Widget _buildOrganicTab() {
    final oc = widget.disease["organic_control"];
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _infoRow(Icons.eco_outlined, "Biological Agent", oc["agent"], Colors.green),
           const Divider(height: 32),
           _infoRow(Icons.settings_input_component, "Application Method", oc["method"], Colors.blueGrey),
           const Divider(height: 32),
           _infoRow(Icons.info_outline, "Expert Note", oc["notes"], Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildChemicalTab() {
    final cc = widget.disease["chemical_control"];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
         _infoRow(Icons.science_outlined, "Recommended Product", cc["product"], Colors.redAccent),
         const Divider(height: 32),
         _infoRow(Icons.water_drop_outlined, "Dosage per Liter", cc["dosage"], Colors.blue),
         const Divider(height: 32),
         _infoRow(Icons.biotech_outlined, "Active Ingredient", cc["active"], Colors.purple),
         const SizedBox(height: 40),
         
         // ⚠️ THE 'ONLY ONE' WARNING BOX
         Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)),
            child: Row(
               children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cc["warning"], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13))),
               ],
            ),
         ),
      ],
    );
  }

  Widget _bulletPoint(String text, {IconData icon = Icons.check_circle_outline}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
         Icon(icon, color: color, size: 24),
         const SizedBox(width: 16),
         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
         ])),
      ],
    );
  }
}
