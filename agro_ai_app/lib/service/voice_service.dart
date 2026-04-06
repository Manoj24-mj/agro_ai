import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:agro_ai_app/localization.dart';

class VoiceService {
  static bool isMaleVoice = false;

  SpeechToText speech = SpeechToText();
  FlutterTts tts = FlutterTts();

  String get _currentLocale {
    switch (Lang.lang) {
      case "kn": return "kn-IN";
      case "hi": return "hi-IN";
      case "en": default: return "en-US";
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

  Future<void> speak(String text) async {
    await tts.setLanguage(_currentLocale);
    
    try {
      List<dynamic> voices = await tts.getVoices;
      String? targetVoiceName;
      
      List<String> femaleIndicators = ["female", "zira", "samantha", "victoria", "karen", "fiona", "catherine", "-c-", "-a-", "siri", "woman"];
      List<String> maleIndicators = ["male", "david", "mark", "daniel", "arthur", "aaron", "-d-", "-b-", "man", "guy", "andrew"];

      for (var v in voices) {
        String name = v["name"].toString().toLowerCase();
        String locale = v["locale"].toString();
        if (locale.startsWith(Lang.lang.split('_')[0])) {
           if (isMaleVoice && maleIndicators.any((ind) => name.contains(ind))) {
               targetVoiceName = v["name"]; break;
           } else if (!isMaleVoice && femaleIndicators.any((ind) => name.contains(ind))) {
               targetVoiceName = v["name"]; break;
           }
        }
      }
      
      // Secondary fallback if exact language/gender match fails
      if (targetVoiceName == null) {
          for (var v in voices) {
             String name = v["name"].toString().toLowerCase();
             if (isMaleVoice && maleIndicators.any((ind) => name.contains(ind))) {
                 targetVoiceName = v["name"]; break;
             } else if (!isMaleVoice && femaleIndicators.any((ind) => name.contains(ind))) {
                 targetVoiceName = v["name"]; break;
             }
          }
      }
      
      if (targetVoiceName != null) {
         Map<String, String> voiceMap = {"name": targetVoiceName, "locale": _currentLocale};
         await tts.setVoice(voiceMap);
         await tts.setPitch(1.0); 
      } else {
         await tts.setPitch(isMaleVoice ? 0.3 : 1.8);
      }
    } catch (e) {
      print("Error swapping voice: $e");
    }

    await tts.speak(text);
  }

  Future<void> stop() async {
    await tts.stop();
  }
}