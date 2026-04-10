import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves user information to Firestore.
  /// Uses phone number as the document ID for uniquely identifying users.
  static Future<void> saveUser(String phone, String name, {String? password}) async {
    try {
      await _db.collection("users").doc(phone).set({
        "name": name,
        "phone": phone,
        "password": password,
        "last_login": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving user: $e");
    }
  }

  /// Checks if a user already exists in the database.
  static Future<Map<String, dynamic>?> checkUser(String phone) async {
    try {
      final doc = await _db.collection("users").doc(phone).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("Error checking user: $e");
    }
    return null;
  }

  /// Saves a scan result to the user's history in Firestore.
  static Future<void> saveScanResult({
    required String phone,
    required String title,
    required String query,
    required String result,
    required String severity,
  }) async {
    try {
      await _db.collection("users").doc(phone).collection("scans").add({
        "title": title,
        "query": query,
        "result": result,
        "severity": severity,
        "timestamp": FieldValue.serverTimestamp(),
      });
      
      // Also update the general history collection for analytics
      await _db.collection("history").add({
        "phone": phone,
        "disease": title,
        "severity": severity,
        "time": FieldValue.serverTimestamp()
      });
    } catch (e) {
      print("Error saving scan: $e");
    }
  }

  /// Saves a chatbot message to Firestore history.
  static Future<void> saveChatMessage({
    required String phone,
    required String message,
    required String reply,
  }) async {
    try {
      // Directing chatbot insights to 'scans' collection so they appear in 'Saved' history
      await _db.collection("users").doc(phone).collection("scans").add({
        "title": "Smart Kisan Advice",
        "query": message,
        "result": reply,
        "severity": "NORMAL",
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving Smart Kisan chat: $e");
    }
  }

  /// Fetches the scan history for a specific user.
  static Stream<QuerySnapshot> getUserScansStream(String phone) {
    return _db
        .collection("users")
        .doc(phone)
        .collection("scans")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// Fetches the chat history for a specific user.
  static Stream<QuerySnapshot> getUserChatsStream(String phone) {
    return _db
        .collection("users")
        .doc(phone)
        .collection("chats")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}