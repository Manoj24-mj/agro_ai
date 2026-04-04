import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/database_service.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> _savedMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMessages();
  }

  Future<void> _loadSavedMessages() async {
    final messages = await DatabaseService.getMessages();
    setState(() {
      _savedMessages = messages.where((m) => m['user'] == 'AI Detector').toList().reversed.toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteResult(int id) async {
    await DatabaseService.deleteMessage(id);
    _loadSavedMessages();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Result deleted!")));
    }
  }

  Future<void> _downloadResult(Map<String, dynamic> item) async {
    final rawText = item['message'];
    final timestampStr = item['timestamp'].toString().split('.').first.replaceAll('T', ' ');
    final cleanTime = item['timestamp'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    
    final formattedText = '''
===================================================
           AGRO AI - DIAGNOSIS REPORT              
===================================================
Date: $timestampStr

$rawText
===================================================
''';

    final filename = 'Agro_AI_Diagnosis_$cleanTime.txt';

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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading report natively to your browser...")));
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsString(formattedText);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report successfully stored locally at: ${file.path}")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.t("saved_title") == "saved_title" ? "Saved Results" : Lang.t("saved_title")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _savedMessages.isEmpty
              ? Center(child: Text("No saved results found.", style: GoogleFonts.inter(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedMessages.length,
                  itemBuilder: (context, index) {
                    final item = _savedMessages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("AI Diagnosis", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green[700])),
                                Text(
                                  item['timestamp'].toString().split('.').first.replaceAll('T', ' '), 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)
                                ),
                              ],
                            ),
                            const Divider(),
                            MarkdownBody(
                              data: item['message'],
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
                                  onPressed: () => Share.share(item['message']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, color: Colors.blue),
                                  tooltip: "Save File natively",
                                  onPressed: () => _downloadResult(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Delete permanently",
                                  onPressed: () => _deleteResult(item['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
