import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class VoiceService {
  static bool isMaleVoice = false;

  SpeechToText speech = SpeechToText();
  FlutterTts tts = FlutterTts();
  List<dynamic>? _voices;

  Future<void> init() async {
    if (_voices == null) {
      try {
        _voices = await tts.getVoices;
      } catch (e) {
        _voices = [];
      }
    }
  }

  String get _currentLocale {
    switch (Lang.lang) {
      case "kn": return "kn-IN";
      case "hi": return "hi-IN";
      case "te": return "te-IN";
      case "ta": return "ta-IN";
      case "mr": return "mr-IN";
      case "bn": return "bn-IN";
      case "gu": return "gu-IN";
      case "ml": return "ml-IN";
      case "pa": return "pa-IN";
      case "en": default: return "en-IN";
    }
  }

  Future startListening(Function(String) onResult) async {
    await speech.initialize();

    speech.listen(
      localeId: _currentLocale.replaceAll('-', '_'),
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }
  
  List<String> _chunkText(String text, int maxLength) {
    List<String> chunks = [];
    List<String> words = text.split(' ');
    String currentChunk = "";
    
    for (String word in words) {
      if ((currentChunk.length + word.length + 1) > maxLength) {
        chunks.add(currentChunk.trim());
        currentChunk = word + " ";
      } else {
        currentChunk += word + " ";
      }
    }
    if (currentChunk.trim().isNotEmpty) {
      chunks.add(currentChunk.trim());
    }
    return chunks;
  }

  Future<void> speak(String text) async {
    String targetLangCode = Lang.lang.split('_')[0].toLowerCase();

    // UNCONDITIONAL Web Fallback for Indian Languages
    // Bypasses flutter_tts entirely for these languages on Chrome because 
    // native Web TTS engines often report they have the voice but play silence.
    if (kIsWeb && ['kn', 'hi', 'te', 'ta', 'mr', 'gu', 'ml', 'pa', 'bn'].contains(targetLangCode)) {
       try {
           print("Using HTML5 Audio bypass for Web TTS: $targetLangCode");
           List<String> chunks = _chunkText(text, 150);
           for (String chunk in chunks) {
              if (chunk.trim().isEmpty) continue;
              // Use client=gtx and translate.googleapis.com which is significantly more stable for cross-origin audio
              String url = 'https://translate.googleapis.com/translate_tts?client=gtx&ie=UTF-8&tl=$targetLangCode&q=${Uri.encodeComponent(chunk)}';
              final audio = html.AudioElement(url);
              
              bool hasEnded = false;
              audio.onEnded.listen((_) => hasEnded = true);
              audio.onError.listen((_) {
                 print("Audio playback error for chunk!");
                 hasEnded = true; 
              });
              
              audio.play().catchError((e) {
                 print("Play block by browser: $e");
                 hasEnded = true;
              });
              
              // Wait for chunk to finish, force continue after 10s if stuck
              int timeoutCount = 0;
              while (!hasEnded && timeoutCount < 100) { // 100 * 100ms = 10s max
                 await Future.delayed(const Duration(milliseconds: 100));
                 timeoutCount++;
              }
              // Wait briefly before next chunk to avoid HTTP 429 Too Many Requests
              await Future.delayed(const Duration(milliseconds: 300));
           }
       } catch (e) {
           print("Web TTS AudioElement playback failed: $e");
       }
       return; 
    }

    await tts.awaitSpeakCompletion(true);
    
    try {
      if (_voices == null) await init();
      List<dynamic> voices = _voices ?? [];
      Map<Object?, Object?>? targetVoice;
      Map<Object?, Object?>? fallbackLangVoice;
      
      List<String> femaleIndicators = ["female", "zira", "samantha", "victoria", "karen", "fiona", "catherine", "-c-", "-a-", "siri", "woman"];
      List<String> maleIndicators = ["male", "david", "mark", "daniel", "arthur", "aaron", "-d-", "-b-", "man", "guy", "andrew"];

      String targetLangCode = Lang.lang.split('_')[0].toLowerCase();

      for (var v in voices) {
        if (v is! Map) continue;
        String name = v["name"].toString().toLowerCase();
        String locale = v["locale"].toString().toLowerCase();
        
        bool matchesLang = locale.startsWith(targetLangCode);
        
        if (matchesLang) {
           fallbackLangVoice ??= v; // Keep the first matching language voice as a safety net
           
           // If on Web, prefer Chrome's Google Network voices as they often support Indian languages
           if (kIsWeb && name.contains("google")) {
              fallbackLangVoice = v;
           }

           // Check for gender preference match
           if (isMaleVoice && maleIndicators.any((ind) => name.contains(ind))) {
               targetVoice = v; break;
           } else if (!isMaleVoice && femaleIndicators.any((ind) => name.contains(ind))) {
               targetVoice = v; break;
           }
        }
      }
      
      // Use exact gender match if found. Otherwise, use ANY voice that natively matches the required language.
      Map<Object?, Object?>? finalVoice = targetVoice ?? fallbackLangVoice;

      if (finalVoice != null) {
         Map<String, String> voiceMap = {
           "name": finalVoice["name"].toString(),
           "locale": finalVoice["locale"].toString()
         };
         await tts.setVoice(voiceMap);
      } else {
         await tts.setLanguage(_currentLocale);
      }
      
      await tts.setPitch(isMaleVoice ? 0.7 : 1.3);
    } catch (e) {
      print("Error configuring TTS voice: $e");
    }

    await tts.speak(text);
  }

  Future<void> stop() async {
    await tts.stop();
  }
}