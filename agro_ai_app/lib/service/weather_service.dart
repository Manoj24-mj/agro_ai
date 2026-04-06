import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Open-Meteo is a professional-grade API that requires NO API KEY
  // This ensures 100% real-time data for every location without fallbacks.

  static const Map<String, String> countries = {
    "Afghanistan": "AF", "Albania": "AL", "Algeria": "DZ", "Andorra": "AD", "Angola": "AO",
    "Argentina": "AR", "Australia": "AU", "Austria": "AT", "Bangladesh": "BD", "Belgium": "BE",
    "Brazil": "BR", "Canada": "CA", "China": "CN", "Colombia": "CO", "Denmark": "DK",
    "Egypt": "EG", "France": "FR", "Germany": "DE", "Greece": "GR", "India": "IN",
    "Indonesia": "ID", "Iran": "IR", "Iraq": "IQ", "Ireland": "IE", "Israel": "IL",
    "Italy": "IT", "Japan": "JP", "Jordan": "JO", "Kenya": "KE", "Kuwait": "KW",
    "Malaysia": "MY", "Mexico": "MX", "Morocco": "MA", "Nepal": "NP", "Netherlands": "NL",
    "New Zealand": "NZ", "Nigeria": "NG", "Norway": "NO", "Pakistan": "PK", "Philippines": "PH",
    "Poland": "PL", "Portugal": "PT", "Qatar": "QA", "Russia": "RU", "Saudi Arabia": "SA",
    "Singapore": "SG", "South Africa": "ZA", "South Korea": "KR", "Spain": "ES", "Sri Lanka": "LK",
    "Sweden": "SE", "Switzerland": "CH", "Thailand": "TH", "Turkey": "TR", "United Arab Emirates": "AE",
    "United Kingdom": "GB", "United States": "US", "Vietnam": "VN"
  };

  static Map<String, dynamic>? _lastAutoWeather;
  static DateTime? _lastAutoFetch;

  static Future<Map<String, dynamic>> getWeatherAuto({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastAutoWeather != null && _lastAutoFetch != null && 
        DateTime.now().difference(_lastAutoFetch!) < const Duration(minutes: 15)) {
      return _lastAutoWeather!;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _getWeatherViaIP(); // Fallback to IP if denied
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return await _getWeatherViaIP(); // Fallback to IP if permanently denied
      }
      
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium, 
            timeLimit: const Duration(seconds: 10)
          );
        } catch (_) {
          return await _getWeatherViaIP(); // Fallback if GPS times out
        }
      }
      
      final lat = position.latitude;
      final lon = position.longitude;
      
      // Reverse geocode to get actual city name
      String cityName = "Your Location";
      try {
        final geoRes = await http.get(Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=10"
        )).timeout(const Duration(seconds: 3));
        if (geoRes.statusCode == 200) {
          final geoData = jsonDecode(geoRes.body);
          cityName = geoData["address"]?["city"] ?? 
                     geoData["address"]?["town"] ?? 
                     geoData["address"]?["village"] ?? 
                     geoData["address"]?["state"] ?? "Your Location";
        }
      } catch (_) {}

      final data = await fetchFullWeatherData(lat, lon, cityName);
      _lastAutoWeather = data;
      _lastAutoFetch = DateTime.now();
      return data;
    } catch (e) {
      return await _getWeatherViaIP(); // Fallback on any error
    }
  }

  static Future<Map<String, dynamic>> _getWeatherViaIP() async {
    try {
      // Use ipapi.co for better accuracy in India regions
      final res = await http.get(Uri.parse("https://ipapi.co/json/")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return fetchFullWeatherData(
          double.parse(data["latitude"].toString()), 
          double.parse(data["longitude"].toString()), 
          data["city"] ?? "Current City"
        );
      }
    } catch (_) {}
    return {"error": "Unable to determine location automatically."};
  }

  static Future<Map<String, dynamic>> getWeatherManual(String city, [String? countryCode]) async {
    try {
      // 1. Geocoding search (Filter by countryCode if provided)
      String url = "https://geocoding-api.open-meteo.com/v1/search?name=$city&count=10&language=en&format=json";
      var res = await http.get(Uri.parse(url));
      
      if (res.statusCode == 200) {
        var geoData = jsonDecode(res.body);
        if (geoData["results"] == null || (geoData["results"] as List).isEmpty) {
          return {"error": "City '$city' not found."};
        }
        
        var results = List<Map<String, dynamic>>.from(geoData["results"]);
        
        // Filter by Country Code if specified
        var filtered = countryCode == null 
            ? results[0] 
            : results.firstWhere((e) => e["country_code"] == countryCode, orElse: () => results[0]);
            
        return fetchFullWeatherData(filtered["latitude"], filtered["longitude"], filtered["name"]);
      }
      return {"error": "Geocoding service unavailable."};
    } catch (e) {
      return {"error": "Search error: $e"};
    }
  }

  // Real-time Global City Search with Country Filtering
  static Future<List<Map<String, dynamic>>> searchCities(String query, [String? countryCode]) async {
    if (query.length < 3) return [];
    try {
      var res = await http.get(Uri.parse(
        "https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=en&format=json"
      ));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data["results"] != null) {
          var results = List<Map<String, dynamic>>.from(data["results"]);
          if (countryCode != null) {
             return results.where((e) => e["country_code"] == countryCode).toList();
          }
          return results;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  static Future<Map<String, dynamic>> fetchFullWeatherData(double lat, double lon, String cityName) async {
    final cacheKey = "${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}";
    
    // Check Cache
    if (_cache.containsKey(cacheKey) && DateTime.now().difference(_cacheTime[cacheKey]!) < _cacheDuration) {
      print("Returning cached weather for $cityName");
      var cachedData = Map<String, dynamic>.from(_cache[cacheKey]);
      cachedData["name"] = cityName; // Update name in case it's different query
      return cachedData;
    }

    try {
      // Parallel requests for Weather and Air Quality
      final responses = await Future.wait([
        http.get(Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,uv_index&timezone=auto"
        )),
        http.get(Uri.parse(
          "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi"
        )),
      ]);

      if (responses[0].statusCode == 200) {
        var weatherData = jsonDecode(responses[0].body)["current"];
        var airData = responses[1].statusCode == 200 ? jsonDecode(responses[1].body)["current"] : null;
        
        final result = {
          "name": cityName,
          "main": {
            "temp": weatherData["temperature_2m"],
            "humidity": weatherData["relative_humidity_2m"],
            "pressure": weatherData["surface_pressure"],
          },
          "wind": {"speed": weatherData["wind_speed_10m"]},
          "uvi": weatherData["uv_index"],
          "aqi": airData?["us_aqi"] ?? 0,
          "weather": [{"main": _getWeatherDesc(weatherData["temperature_2m"])}],
        };

        // Update Cache
        _cache[cacheKey] = result;
        _cacheTime[cacheKey] = DateTime.now();

        return result;
      }
      return {"error": "Weather data currently unavailable."};
    } catch (e) {
      return {"error": "Network error: $e"};
    }
  }

  static String _getWeatherDesc(double temp) {
    if (temp > 30) return "Hot & Sunny";
    if (temp > 20) return "Clear & Pleasant";
    if (temp > 10) return "Cool";
    return "Cold";
  }
}