import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MarketService {
  static const String _productsKey = "market_products_db";
  static const String _cartKey = "market_cart_db";

  // Realistic fallback starting mock data resembling a populated database
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
      "cat": "Seeds"
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
      "cat": "Fertilizers"
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
      "cat": "Tools"
    },
    {
      "id": "4", 
      "name": "Premium Pesticide (Eco-Friendly)", 
      "price": "₹450", 
      "distance": "1.2 km", 
      "rating": 4.2, 
      "reviews": 15, 
      "seller": "Local Chemical Depot", 
      "isVerified": false, 
      "demand": "LOW", 
      "cat": "Pesticides"
    },
     {
      "id": "5", 
      "name": "Rice Paddy Harvest Bundle", 
      "price": "₹6500", 
      "distance": "3.5 km", 
      "rating": 4.7, 
      "reviews": 88, 
      "seller": "Green Farms Ltd", 
      "isVerified": true, 
      "demand": "HIGH", 
      "cat": "Crops"
    },
  ];

  /// Fetches all active products from local persistent storage (Mimics Firestore fetch)
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_productsKey);
      if (data == null) {
        // Initialize DB on first run
        await prefs.setString(_productsKey, jsonEncode(_initialMockProducts));
        return _initialMockProducts;
      }
      List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return _initialMockProducts;
    }
  }

  /// Adds a newly created product globally to the database
  static Future<void> addProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> products = await getProducts();
    // Insert new products at the top of the feed mimicking newest-first DB sorting
    products.insert(0, product); 
    await prefs.setString(_productsKey, jsonEncode(products));
  }

  /// Fetches current active user's localized cart 
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

  /// Pushes an item to the persistent cart state
  static Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cart = await getCart();
    cart.add(product);
    await prefs.setString(_cartKey, jsonEncode(cart));
  }
  
  /// Clears cart upon successful checkout payment 
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
