import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_ai_app/screens/scan_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String? _userPhone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhone = prefs.getString('userPhone');
      _isLoading = false;
    });
  }

  Future<void> _deleteResult(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_userPhone)
          .collection("scans")
          .doc(docId)
          .delete();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("report_deleted_msg"))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete error: $e")));
    }
  }

  Future<void> _downloadResult(Map<String, dynamic> item) async {
    final rawText = item['result'] ?? "No result";
    final dt = (item['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timestampStr = dt.toString().split('.').first;
    final cleanTime = dt.millisecondsSinceEpoch.toString();
    
    final formattedText = '''
===================================================
           SMART KISAN - DIAGNOSIS REPORT              
===================================================
Plant: ${item['title'] ?? 'Unknown'}
Severity: ${item['severity'] ?? 'N/A'}
Date: $timestampStr

$rawText
===================================================
''';

    final filename = 'Smart_Kisan_Diagnosis_$cleanTime.txt';

    try {
      if (kIsWeb) {
        final textBytes = utf8.encode(formattedText);
        final blob = html.Blob([textBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("downloading_msg"))));
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$filename';
        final file = io.File(filePath);
        await file.writeAsString(formattedText);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${Lang.t("stored_locally_msg")} $filePath")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    }
  }

  Future<void> _clearAllResults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Lang.t("clear_saved_confirm")),
        content: Text(Lang.t("clear_saved_body")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Lang.t("cancel"))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(Lang.t("clear_all_btn"), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final query = await FirebaseFirestore.instance
            .collection("users")
            .doc(_userPhone)
            .collection("scans")
            .get();
        
        // Batch delete is safer for smaller collections
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud history cleared successfully!")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Clear error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.t("saved_cloud_title")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: "Clear All Cloud History",
            onPressed: () => _clearAllResults(),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _userPhone == null 
              ? Center(child: Text(Lang.t("login_required_saved")))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.getUserScansStream(_userPhone!),
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(Lang.t("no_saved_cloud"), style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        );
                     }

                     return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final item = doc.data() as Map<String, dynamic>;
                          final dt = (item['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanDetailScreen(item: item),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.cloud_done, color: Colors.blue, size: 16),
                                          const SizedBox(width: 8),
                                          Text(item['title'] ?? "AI Diagnosis", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green[700])),
                                        ],
                                      ),
                                      Text(
                                        "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}", 
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  MarkdownBody(
                                    data: item['result'] ?? "No data available.",
                                    styleSheet: MarkdownStyleSheet(
                                      p: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.black87),
                                      h1: GoogleFonts.outfit(color: Colors.green[800], fontSize: 18, fontWeight: FontWeight.bold),
                                      h2: GoogleFonts.outfit(color: Colors.green[700], fontSize: 16, fontWeight: FontWeight.bold),
                                      h3: GoogleFonts.outfit(color: Colors.green[600], fontSize: 14, fontWeight: FontWeight.bold),
                                      strong: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.orange),
                                        tooltip: "Share Result",
                                        onPressed: () => Share.share(item['result'] ?? ""),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download, color: Colors.blue),
                                        tooltip: "Download Report",
                                        onPressed: () => _downloadResult(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: "Delete from Cloud",
                                        onPressed: () => _deleteResult(doc.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ),
                            ),
                          );
                        },
                     );
                  },
                ),
    );
  }
}

