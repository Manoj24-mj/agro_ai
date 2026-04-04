import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> saveHistory(String disease) async {
    FirebaseFirestore.instance.collection("history").add({
      "disease": disease,
      "time": DateTime.now()
    });
  }
}