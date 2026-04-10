import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/localization.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = AgroDataService.getAnalytics();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(Lang.t("analytics_title")),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Cards
            Row(
              children: [
                _buildStatCard(Lang.t("total_scans"), analytics["totalScans"].toString(), Icons.camera_alt, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(Lang.t("active_users"), analytics["activeUsers"].toString(), Icons.people, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            
            // 2. High-Impact Metrics
            _buildMetricBar(Lang.t("most_detected"), analytics["topDisease"], Icons.bug_report, Colors.red),
            const SizedBox(height: 16),
            _buildMetricBar(Lang.t("dislike_rate"), analytics["dislikeRate"], Icons.thumb_down, Colors.orange),
            const SizedBox(height: 16),
            _buildMetricBar(Lang.t("alert_reach"), analytics["alertReach"], Icons.rss_feed, Colors.purple),
            
            const SizedBox(height: 32),
            
            // 3. Trends Section
            Text(Lang.t("regional_trends"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTrendItem("North India", "Wheat Rust Increasing (High)", Colors.red),
            _buildTrendItem("South India", "Paddy Blast Stable (Moderate)", Colors.orange),
            _buildTrendItem("West India", "Cotton Bollworm Low", Colors.green),
            
            const SizedBox(height: 40),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: Text(Lang.t("down_report")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
             Icon(icon, color: color, size: 32),
             const SizedBox(height: 12),
             Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
           Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
           const SizedBox(width: 16),
           Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
           Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String region, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
           Icon(Icons.circle, size: 10, color: color),
           const SizedBox(width: 12),
           Expanded(child: Text(region, style: const TextStyle(fontWeight: FontWeight.bold))),
           Text(detail, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}
