import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/screens/disease_detail_screen.dart';

class DiseaseAlertScreen extends StatefulWidget {
  const DiseaseAlertScreen({super.key});

  @override
  State<DiseaseAlertScreen> createState() => _DiseaseAlertScreenState();
}

class _DiseaseAlertScreenState extends State<DiseaseAlertScreen> {
  final List<Map<String, dynamic>> _alerts = AgroDataService.alerts;
  String _filter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("🚨 Disease Alerts"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Regional Control Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                const Expanded(child: Text("Current Region Tracking: North / South India", style: TextStyle(fontWeight: FontWeight.bold))),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _filter = v),
                  itemBuilder: (context) => ["All", "High", "Moderate", "Wheat", "Sugar"]
                    .map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(_filter, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          
          // 2. Alert Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _alerts.length,
              itemBuilder: (context, i) {
                final alert = _alerts[i];
                if (_filter != "All" && !alert["severity"].contains(_filter) && !alert["crop"].contains(_filter)) return const SizedBox.shrink();
                
                return _buildAlertCard(alert);
              },
            ),
          ),
          
          // 3. Subscription Widget
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.red.shade800]),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Turn on Push Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Get instant alerts for your crops.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )),
                Switch(value: true, onChanged: (v) {}, activeColor: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    bool isHigh = alert["severity"] == "High";
    
    return GestureDetector(
      onTap: () {
        // Find matching disease or use default
        final disease = AgroDataService.diseaseDatabase.firstWhere(
           (d) => d['crop'].toString().contains(alert['crop']) || d['name'].toString().contains(alert['crop']),
           orElse: () => AgroDataService.diseaseDatabase[0],
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => DiseaseDetailScreen(disease: disease)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHigh ? Colors.red.shade200 : Colors.orange.shade200, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isHigh ? Colors.red.shade800 : Colors.orange.shade800,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${alert["severity"]} Severity", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(alert["date"], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CROP AFFECTED: ${alert["crop"]}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14)),
                    const SizedBox(height: 12),
                    Text(alert["message"], style: const TextStyle(color: Colors.blueGrey, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
                    const SizedBox(height: 20),
                    Row(
                       children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text("ACTION REQUIRED: Contact Local Agro-Expert", style: TextStyle(color: Colors.red[800], fontSize: 11, fontWeight: FontWeight.bold)),
                       ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
