import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:agro_ai_app/localization.dart';

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const ScanDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String title = item['title'] != null ? item['title'] : Lang.t("plant_scan");
    // Check both local and cloud keys
    final String details = item['details'] ?? item['result'] ?? Lang.t("no_summary");
    final String severity = item['severity'] ?? "LOW";
    
    dynamic timestampData = item['timestamp'];
    DateTime dt;
    if (timestampData is String) {
      dt = DateTime.tryParse(timestampData) ?? DateTime.now();
    } else if (timestampData is Timestamp) {
      // Handle Firestore Timestamp
      dt = timestampData.toDate();
    } else {
      dt = DateTime.now();
    }
    
    final bool isChat = item['type'] == 'chat' || title.contains("Advice");

    Color severityColor = Colors.green;
    IconData severityIcon = Icons.check_circle;

    if (severity == "HIGH") {
      severityColor = Colors.redAccent;
      severityIcon = Icons.warning;
    } else if (severity == "MEDIUM") {
      severityColor = Colors.orange;
      severityIcon = Icons.energy_savings_leaf;
    }


    String timeStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isChat ? Lang.t("chat_detail") : Lang.t("scan_report")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share("Smart Kisan Report: $title\n\n$details"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: severityColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(isChat ? Icons.chat_bubble : severityIcon, color: severityColor, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!isChat)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Lab Report Section
            Text(
              isChat ? Lang.t("conv_record") : Lang.t("det_analysis"),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            
            MarkdownBody(
              data: details,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(fontSize: 15, height: 1.6, color: Colors.black87),
                h1: GoogleFonts.outfit(color: Colors.green[800], fontSize: 22, fontWeight: FontWeight.bold),
                h2: GoogleFonts.outfit(color: Colors.green[700], fontSize: 18, fontWeight: FontWeight.bold),
                h3: GoogleFonts.outfit(color: Colors.green[600], fontSize: 16, fontWeight: FontWeight.bold),
                strong: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: Colors.green[800]),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Advisory Note
            if (!isChat)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Lang.t("ai_disclaimer"),
                        style: TextStyle(fontSize: 12, color: Colors.blue[900], fontStyle: FontStyle.italic),
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
