import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _key = "chat_history";

  static Future<void> saveMessage(String user, String message, bool isUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? data = prefs.getString(_key);
      List<dynamic> historyList = [];
      if (data != null) {
        historyList = jsonDecode(data);
      }
      
      Map<String, dynamic> newMsg = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user': user,
        'message': message,
        'isUser': isUser ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      historyList.add(newMsg);
      await prefs.setString(_key, jsonEncode(historyList));
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_key);
      
      if (data == null) return [];
      
      List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print("Error reading messages: $e");
      return [];
    }
  }

  static Future<void> deleteMessage(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_key);
      if (data == null) return;
      
      List<dynamic> decoded = jsonDecode(data);
      decoded.removeWhere((e) => e['id'] == id);
      await prefs.setString(_key, jsonEncode(decoded));
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  // --- HISTORY SCREEN LOGIC ---
  static const String _historyKey = "scan_history";

  static Future<void> saveHistory(String title, String summary, String details, String severity, {String type = 'scan'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_historyKey);
      List<dynamic> historyList = data != null ? jsonDecode(data) : [];
      
      Map<String, dynamic> item = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': type,
        'title': title,
        'summary': summary,
        'details': details,
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      historyList.insert(0, item); // Insert at top
      await prefs.setString(_historyKey, jsonEncode(historyList));
    } catch (e) {
      print("Error saving history: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_historyKey);
      if (data == null) return [];
      List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}

