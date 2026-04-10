import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _productsRef = _db.collection("products");

  /// Initial seed data if Firestore is empty
  static final List<Map<String, dynamic>> _initialMockProducts = [
    {
      "id": "1", 
      "name": "Organic Wheat Seeds (Premium)", 
      "price": "₹1200", 
      "distance": "2.4 km", 
      "rating": 4.8, 
      "reviews": 120, 
      "seller": "Green Farms Ltd", 
      "isVerified": true, 
      "demand": "HIGH", 
      "cat": "Seeds",
      "timestamp": FieldValue.serverTimestamp()
    },
    {
      "id": "2", 
      "name": "Urea Fertilizer 50kg Sack", 
      "price": "₹800", 
      "distance": "5.1 km", 
      "rating": 4.5, 
      "reviews": 34, 
      "seller": "AgroTech Supplies", 
      "isVerified": false, 
      "demand": "NORMAL", 
      "cat": "Fertilizers",
      "timestamp": FieldValue.serverTimestamp()
    },
    {
      "id": "3", 
      "name": "Heavy Duty Cultivator Machine", 
      "price": "₹12500", 
      "distance": "8.0 km", 
      "rating": 4.9, 
      "reviews": 210, 
      "seller": "Ravi Tools & Spares", 
      "isVerified": true, 
      "demand": "TRENDING", 
      "cat": "Tools",
      "timestamp": FieldValue.serverTimestamp()
    },
  ];

  /// One-time seed method to populate Firestore for the first time
  static Future<void> seedDatabase() async {
    final snapshot = await _productsRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (var product in _initialMockProducts) {
        await _productsRef.add(product);
      }
      print("Firestore Market Seeded successfully.");
    }
  }

  /// Fetches all active products from Firestore (Real-time compatible)
  static Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _productsRef.orderBy("timestamp", descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Map document ID
        return data;
      }).toList();
    });
  }

  /// Adds a newly created product globally to Firestore
  static Future<void> addProduct(Map<String, dynamic> product) async {
    product['timestamp'] = FieldValue.serverTimestamp();
    await _productsRef.add(product);
  }

  // --- CART MANAGEMENT (Local Storage) ---
  static const String _cartKey = "market_cart_db";

  static Future<List<Map<String, dynamic>>> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cartKey);
      if (data == null) return [];
      List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cart = await getCart();
    cart.add(product);
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
