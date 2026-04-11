import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/voice_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/gemini_service.dart';
import 'package:agro_ai_app/service/weather_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:agro_ai_app/service/database_service.dart';
import 'package:agro_ai_app/service/data_service.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final List<DetectorMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isScanning = false;
  bool _isListening = false;
  bool _isVoiceEnabled = false;


  @override
  void initState() {
    super.initState();
    _messages.add(DetectorMessage(
      message: Lang.t("detector_welcome"),
      isUser: false,
    ));
    Lang().addListener(_onLangChanged);
  }

  void _onLangChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _cameraController?.dispose();
    Lang().removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showError("Camera permission denied.");
        return;
      }
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      _showError("No cameras found.");
      return;
    }

    await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_cameraController != null) {
      await _cameraController?.dispose();
    }

    _cameraController = CameraController(_cameras[_currentCameraIndex], ResolutionPreset.medium, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      _showError("Camera error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    setState(() => _isCameraReady = false);
    await _startCamera();
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processMessage(String msg, {XFile? image, bool isRetry = false}) async {
    if (msg.trim().isEmpty && image == null) return;

    setState(() {
      _messages.add(DetectorMessage(
        message: msg,
        isUser: true,
        imagePath: image?.path,
      ));
      _messages.add(DetectorMessage(
        message: isRetry ? "🔄 Re-analyzing with high scrutiny..." : Lang.t("thinking"),
        isUser: false,
      ));
    });
    _scrollToBottom();
    _controller.clear();

    try {
      final weatherFuture = WeatherService.getWeatherAuto();
      final imageBytesFuture = image?.readAsBytes();

      String basePrompt = image != null 
          ? "Please analyze this plant image."
          : "Based on this description: '$msg', analyze the plant issue.";
          
      if (isRetry) {
        basePrompt = "The previous result was flagged as incorrect. Please PERFORM A DEEP RE-ANALYSIS. Look for subtle symptoms, cross-reference with similar diseases, and provide an extremely cautious and detailed second opinion. " + basePrompt;
      }

      final weatherData = await weatherFuture;
      final imageBytes = await imageBytesFuture;

      String weatherContext = "";
      if (weatherData["error"] == null) {
        final loc = weatherData["name"] ?? "Unknown";
        final hum = weatherData["main"]?["humidity"] ?? "Unknown";
        final temp = weatherData["main"]?["temp"] ?? "Unknown";
        weatherContext = "\n\nCRITICAL CONTEXT: The user is currently in $loc. The temperature is $temp°C and relative humidity is $hum%. Please take this specific climate and location into account when diagnosing the plant disease, explaining why this weather might cause it, and providing climate-specific prevention steps.";
      }
      
      String prompt = '''
$basePrompt

You MUST act as a high-end agricultural university laboratory. Generate a minimalist, ultra-professional digital lab report.
Strictly use the following markdown formatting EXACTLY as shown.
IMPORTANT: You must include the EXACT strings at the very beginning of your response:
[ACCURACY: 95] (confidence 0-100)
[SEVERITY: HIGH] (or MEDIUM/LOW)
[WATER: 60] (amount of water needed in percent 0-100 based on the disease)
[TEMP: 25] (extract the temperature number from context below)
[HUMIDITY: 40] (extract the humidity number from context below)

[ACCURACY: 95]
[SEVERITY: HIGH]
[WATER: 60]
[TEMP: 25]
[HUMIDITY: 40]

---
## 📋 Section 1: Metadata
- **Plant Type:** [Identify the plant]
- **Location & Climate:** [Use environment data provided below]

---
## 🔬 Section 2: Visual Evidence & Cause
- **Diagnosis:** [Name of disease/pest]
- **Evidence/Observation:** [What exactly do you see? Cropped macro context, e.g., 'aphids visible on lower leaves']
- **Why it occurred:** [Explain in detail WHY this disease occurs, explicitly factoring in the climate/weather provided]

---
## 🧪 Section 3: The Prescription & Prevention
**1. Immediate Remedies:**
- [Step 1]
- [Step 2]

**2. Eradication (Pesticides & Dosage):**
- [Chemical/Pesticide Name] - [Exact Dosage]

**3. Recovery (Best Fertilizers):**
- [Fertilizer Name/Type] - [Exact Dosage]

**4. Future Prevention:**
- [How to prevent this from returning]
''';
      
      prompt += weatherContext;
      
      final result = await _geminiService.askGemini(
        prompt,
        imageBytes: imageBytes,
        languageCode: Lang.lang,
      );

      // --- AUTO SAVE TO HISTORY ---
      String title = "Detector Scan";
      String severity = "LOW";
      final diagMatch = RegExp(r'\*\*Diagnosis:\*\*\s*(.+)').firstMatch(result);
      if (diagMatch != null) {
         title = diagMatch.group(1)!;
         if (title.length > 30) title = title.substring(0, 30) + "...";
      }
      final sevMatch = RegExp(r'\[\s*SEVERITY:\s*(HIGH|MEDIUM|LOW)\s*\]', caseSensitive: false).firstMatch(result);
      if (sevMatch != null) severity = sevMatch.group(1)!.toUpperCase();
      
      await DatabaseService.saveHistory(
        title, 
        image != null ? "Image Analysis Request" : msg, 
        result, 
        severity
      );
      
      // (Automatic Cloud upload removed as per user request. Use manual 'Save' button instead.)

      setState(() {
        _messages.removeLast();
        _messages.add(DetectorMessage(message: result, isUser: false, originalImage: image));
      });

      if (_isVoiceEnabled) {
        _voiceService.speak(result);
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(DetectorMessage(message: "Analysis error: ${e.toString()}", isUser: false));
      });
    }
    _scrollToBottom();
  }

  void _handleFeedback(DetectorMessage msg, bool isHelpful) {
    if (isHelpful) {
      AgroDataService.submitFeedback("AI Detector", msg.message.hashCode.toString(), "Helpful");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("helpful_msg_thanks"))));
    } else {
      _showDislikeOptions(msg);
    }
  }

  void _showDislikeOptions(DetectorMessage msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Lang.t("improve_msg"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: Text(Lang.t("deep_analysis")),
              subtitle: const Text("Run AI with higher sensitivity settings."),
              onTap: () {
                Navigator.pop(context);
                _processMessage("Requesting refined analysis...", image: msg.originalImage, isRetry: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: Text(Lang.t("inaccurate_res")),
              onTap: () {
                AgroDataService.submitFeedback("AI Detector", msg.message.hashCode.toString(), "Inaccurate");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t("feedback_msg"))));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScanning() async {
    if (_isScanning) {
      setState(() => _isScanning = false);
      return;
    }

    if (!_isCameraReady) {
      await _initCamera();
    }

    if (_isCameraReady) {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _isScanning = false);
      _processMessage("Analyzing this live scan...", image: photo);
    } catch (e) {
      _showError("Capture failed: $e");
    }
  }

  Future<void> _uploadFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      _processMessage("Analyzing uploaded photo...", image: photo);
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _voiceService.speech.stop();
      setState(() => _isListening = false);
    } else {
      _voiceService.startListening((text) {
        if (text.isNotEmpty) {
           setState(() => _isListening = false);
           _processMessage(text);
        }
      });
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(Lang.t("detector_title")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isVoiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _isVoiceEnabled = !_isVoiceEnabled;
                if (!_isVoiceEnabled) _voiceService.stop();
              });
            },
            tooltip: "Toggle Voice Output",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning && _isCameraReady)
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   CameraPreview(_cameraController!),
                   Container(
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.green.withOpacity(0.5), width: 3),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     width: 250,
                     height: 250,
                   ),
                   Positioned(
                     top: 20,
                     right: 20,
                     child: IconButton(
                       icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                       onPressed: _switchCamera,
                       tooltip: "Switch Camera",
                     ),
                   ),
                   Positioned(
                     bottom: 20,
                     child: ElevatedButton.icon(

                        icon: const Icon(Icons.flash_on),
                        label: const Text("Capture & Analyze"),
                        onPressed: _captureAndAnalyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                     ),
                   ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _DetectorBubble(
                  message: msg.message,
                  isUser: msg.isUser,
                  imagePath: msg.imagePath,
                  onVoice: () => _voiceService.speak(msg.message),
                  onHelpful: () => _handleFeedback(msg, true),
                  onDislike: () => _handleFeedback(msg, false),
                  onSave: msg.isUser || msg.message == Lang.t("thinking") || msg.message.contains("🔄") ? null : () async {
                     final prefs = await SharedPreferences.getInstance();
                     final phone = prefs.getString('userPhone') ?? "Anonymous";

                     // 1. Save Locally
                     await DatabaseService.saveMessage("AI Detector", msg.message, false);

                     // 2. Save to Cloud (Manual Choice)
                     try {
                        String title = "Detector Scan";
                        String severity = "LOW";
                        final diagMatch = RegExp(r'\*\*Diagnosis:\*\*\s*(.+)').firstMatch(msg.message);
                        if (diagMatch != null) {
                           title = diagMatch.group(1)!;
                           if (title.length > 30) title = title.substring(0, 30) + "...";
                        }
                        final sevMatch = RegExp(r'\[\s*SEVERITY:\s*(HIGH|MEDIUM|LOW)\s*\]', caseSensitive: false).firstMatch(msg.message);
                        if (sevMatch != null) severity = sevMatch.group(1)!.toUpperCase();

                        await FirebaseService.saveScanResult(
                          phone: phone,
                          title: title,
                          query: msg.imagePath != null ? "Image Analysis" : "Text Query",
                          result: msg.message,
                          severity: severity,
                        );
                     } catch (e) {
                        debugPrint("Firebase manual save error: $e");
                     }

                     if (context.mounted) {
                       showDialog(
                         context: context,
                         builder: (context) => AlertDialog(
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                           title: Row(
                             children: [
                               Icon(Icons.cloud_done, color: Colors.blue, size: 28),
                               SizedBox(width: 10),
                               Text(Lang.t("saved_cloud"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                             ],
                           ),
                           content: Text(Lang.t("saved_cloud_body"), style: const TextStyle(fontSize: 16)),
                           actions: [
                             TextButton(
                               onPressed: () => Navigator.pop(context),
                               child: Text(Lang.t("awesome"), style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                             )
                           ],
                         ),
                       );
                     }
                  },
                  onShare: msg.isUser || msg.message == Lang.t("thinking") ? null : () {
                     Share.share(msg.message);
                  },
                  onScanAgain: msg.isUser || msg.message == Lang.t("thinking") ? null : () {
                     _startScanning();
                  },
                );
              },
            ),
          ),
          _DetectorInput(
            controller: _controller,
            isListening: _isListening,
            onSend: () => _processMessage(_controller.text),
            onMic: _toggleListening,
            onScan: _startScanning,
            onUpload: _uploadFromGallery,
          ),
        ],
      ),
    );
  }
}

class DetectorMessage {
  final String message;
  final bool isUser;
  final String? imagePath;
  final XFile? originalImage;

  DetectorMessage({required this.message, required this.isUser, this.imagePath, this.originalImage});
}

class _DetectorBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? imagePath;
  final VoidCallback onVoice;
  final VoidCallback? onHelpful;
  final VoidCallback? onDislike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onScanAgain;

  const _DetectorBubble({
      super.key, 
      required this.message, 
      required this.isUser, 
      this.imagePath, 
      required this.onVoice, 
      this.onHelpful,
      this.onDislike,
      this.onSave, 
      this.onShare, 
      this.onScanAgain
  });

  Widget _buildDial(String label, int value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(
                value: value >= 100 ? 1.0 : (value / 100.0),
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 4,
              )
            ),
            Text("$value$unit", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ]
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    int? accuracy; String severity = "LOW"; int? water; int? temp; int? humidity;
    String cleanMessage = message;

    if (!isUser) {
      final accReg = RegExp(r'\[\s*ACCURACY:\s*(\d+)%?\s*\]', caseSensitive: false);
      final sevReg = RegExp(r'\[\s*SEVERITY:\s*(HIGH|MEDIUM|LOW)\s*\]', caseSensitive: false);
      final waterReg = RegExp(r'\[\s*WATER:\s*(\d+)%?\s*\]', caseSensitive: false);
      final tempReg = RegExp(r'\[\s*TEMP:\s*(-?\d*\.?\d+).*?\]', caseSensitive: false);
      final humReg = RegExp(r'\[\s*HUMIDITY:\s*(\d+)%?\s*\]', caseSensitive: false);

      final aM = accReg.firstMatch(cleanMessage); if (aM != null) { accuracy = int.tryParse(aM.group(1)!); cleanMessage = cleanMessage.replaceAll(aM.group(0)!, ''); }
      final sM = sevReg.firstMatch(cleanMessage); if (sM != null) { severity = sM.group(1)!.toUpperCase(); cleanMessage = cleanMessage.replaceAll(sM.group(0)!, ''); }
      final wM = waterReg.firstMatch(cleanMessage); if (wM != null) { water = int.tryParse(wM.group(1)!); cleanMessage = cleanMessage.replaceAll(wM.group(0)!, ''); }
      final tM = tempReg.firstMatch(cleanMessage); if (tM != null) { temp = double.tryParse(tM.group(1)!)?.toInt(); cleanMessage = cleanMessage.replaceAll(tM.group(0)!, ''); }
      final hM = humReg.firstMatch(cleanMessage); if (hM != null) { humidity = int.tryParse(hM.group(1)!); cleanMessage = cleanMessage.replaceAll(hM.group(0)!, ''); }
      
      cleanMessage = cleanMessage.trim();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
        decoration: BoxDecoration(
          color: isUser ? null : Colors.white,
          gradient: isUser 
              ? LinearGradient(colors: [Colors.green[600]!, Colors.teal[500]!], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          borderRadius: isUser 
              ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4))
              : BorderRadius.circular(8),
          border: isUser ? null : Border.all(color: Colors.green[800]!, width: 1.5),
          boxShadow: isUser ? [] : [
            const BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message != Lang.t("thinking") && message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(Lang.t("bot_report"), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2, fontSize: 13)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && message != Lang.t("thinking") && accuracy != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 4.0),
                      child: Container(
                         width: double.infinity,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                         child: Wrap(
                           alignment: WrapAlignment.spaceEvenly,
                           spacing: 12,
                           runSpacing: 20,
                           children: [
                              _buildDial(Lang.t("confidence"), accuracy!, "%", accuracy > 80 ? Colors.green : (accuracy > 50 ? Colors.orange : Colors.red)),
                              _buildDial(Lang.t("threat_lvl"), severity == 'HIGH' ? 85 : (severity == 'MEDIUM' ? 55 : 25), "%", severity == 'HIGH' ? Colors.red : (severity == 'MEDIUM' ? Colors.orange : Colors.green)),
                              if (water != null) _buildDial(Lang.t("water_need"), water, "%", Colors.cyan),
                              if (temp != null) _buildDial(Lang.t("temp_label_short"), temp, "°C", Colors.orange[800]!),
                              if (humidity != null) _buildDial(Lang.t("hum_label_short"), humidity, "%", Colors.teal),
                           ]
                         )
                      ),
                    ),
                  if (imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
                          child: kIsWeb 
                              ? Image.network(imagePath!, fit: BoxFit.cover, height: 120, width: 120)
                              : Image.file(io.File(imagePath!), fit: BoxFit.cover, height: 120, width: 120),
                        ),
                      ),
                    ),
                  if (message.isNotEmpty)
                    MarkdownBody(
                      data: cleanMessage,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(color: isUser ? Colors.white : const Color(0xFF2C3E50), fontSize: 14, height: 1.6),
                        h1: GoogleFonts.outfit(color: Colors.green[900], fontSize: 20, fontWeight: FontWeight.bold),
                        h2: GoogleFonts.outfit(color: Colors.green[800], fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        h3: GoogleFonts.inter(color: Colors.green[700], fontSize: 15, fontWeight: FontWeight.bold),
                        strong: GoogleFonts.inter(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        listBullet: TextStyle(color: isUser ? Colors.white : Colors.green[800]),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.green[100]!, width: 1.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isUser && message.isNotEmpty && message != Lang.t("thinking") && !message.contains("🔄"))
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Row(
                       children: [
                         if (onHelpful != null)
                           IconButton(
                             icon: const Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.green),
                             onPressed: onHelpful,
                             tooltip: "Helpful",
                           ),
                         if (onDislike != null)
                           IconButton(
                             icon: const Icon(Icons.thumb_down_alt_outlined, size: 20, color: Colors.red),
                             onPressed: onDislike,
                             tooltip: "Not Helpful",
                           ),
                         const SizedBox(width: 8),
                         if (onSave != null)
                           IconButton(
                             icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.blue),
                             tooltip: "Save Result",
                             onPressed: onSave,
                           ),
                         if (onShare != null)
                           IconButton(
                             icon: const Icon(Icons.share_outlined, size: 20, color: Colors.orange),
                             tooltip: "Share Result",
                             onPressed: onShare,
                           ),
                       ],
                     ),
                     IconButton(
                       icon: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                         child: Icon(Icons.volume_up, size: 20, color: Colors.green[700]),
                       ),
                       onPressed: onVoice,
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

class _DetectorInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final VoidCallback onScan;
  final VoidCallback onUpload;

  const _DetectorInput({
    required this.controller,
    required this.isListening,
    required this.onSend,
    required this.onMic,
    required this.onScan,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[100],
            child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.green), onPressed: onScan, tooltip: "Live Scan"),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: IconButton(icon: const Icon(Icons.photo_library, color: Colors.blue), onPressed: onUpload, tooltip: "Upload from Gallery"),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: isListening ? Colors.red[100] : Colors.grey[100],
            child: IconButton(
              icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : Colors.green),
              onPressed: onMic,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: Lang.t("detector_hint"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[150],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: onSend),
        ],
      ),
    );
  }
}
