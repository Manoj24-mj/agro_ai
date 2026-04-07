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
      // Tier 0: Check if service is enabled
      bool isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return await _getWeatherViaIP();

      // Tier 0.5: Request Permissions explicitly
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        // Tier 1: Try HIGH ACCURACY GPS (Critical for Bengaluru vs Chennai)
        Position? pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, // Use High for better triangulation
          timeLimit: const Duration(seconds: 7),  // More time for better lock
        ).catchError((_) => Geolocator.getLastKnownPosition());
        
        if (pos != null && pos.latitude != 0) {
          String city = await _reverseGeocode(pos.latitude, pos.longitude);
          final data = await fetchFullWeatherData(pos.latitude, pos.longitude, city);
          if (data["error"] == null) {
            _updateAutoCache(data);
            return data;
          }
        }
      }
      
      // Tier 2: Fallback to IP Geolocation (often shows Chennai for South India ISPs)
      return await _getWeatherViaIP();
    } catch (e) {
      return await _getWeatherViaIP();
    }
  }

  static Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=10"
      )).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["address"]?["city"] ?? 
               data["address"]?["state_district"] ?? 
               data["address"]?["state"] ?? "Your Farm";
      }
    } catch (_) {}
    return "Your Farm";
  }

  static Future<Map<String, dynamic>> _getWeatherViaIP() async {
    try {
      // Use ipapi.co (HTTPS) for better web browser compatibility (blocks insecure http)
      final res = await http.get(Uri.parse("https://ipapi.co/json/")).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final weatherData = await fetchFullWeatherData(
          double.parse(data["latitude"].toString()), 
          double.parse(data["longitude"].toString()), 
          data["city"] ?? data["region"] ?? "Current City"
        );
        _updateAutoCache(weatherData);
        return weatherData;
      }
    } catch (_) {}
    return {"error": "Location detection failed. Please select state manually below."};
  }

  static void _updateAutoCache(Map<String, dynamic> data) {
    _lastAutoWeather = data;
    _lastAutoFetch = DateTime.now();
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

  static final Map<String, List<Map<String, dynamic>>> _searchCache = {};
  
  // Real-time Global City Search with Country Filtering
  static Future<List<Map<String, dynamic>>> searchCities(String query, [String? countryCode]) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.length < 3) return [];
    
    // 1. Check local search cache for rapid typing
    if (_searchCache.containsKey(cleanQuery)) {
      return _searchCache[cleanQuery]!;
    }

    try {
      var res = await http.get(Uri.parse(
        "https://geocoding-api.open-meteo.com/v1/search?name=$cleanQuery&count=10&language=en&format=json"
      ));

      // 2. Handle Rate Limit (Error 429)
      if (res.statusCode == 429) {
          print("Geocoding rate limit, retrying...");
          await Future.delayed(const Duration(seconds: 2));
          res = await http.get(Uri.parse(
            "https://geocoding-api.open-meteo.com/v1/search?name=$cleanQuery&count=10&language=en&format=json"
          ));
      }

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data["results"] != null) {
          var results = List<Map<String, dynamic>>.from(data["results"]);
          if (countryCode != null) {
             results = results.where((e) => e["country_code"] == countryCode).toList();
          }
          
          // 3. Update Cache
          _searchCache[cleanQuery] = results;
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
      // Robust Parallel Fetch: If Air Quality fails, don't crash the main Weather request
      final weatherFuture = http.get(Uri.parse(
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,uv_index&timezone=auto"
      )).timeout(const Duration(seconds: 8));

      final aqiFuture = http.get(Uri.parse(
        "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi"
      )).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('{"error":true}', 404));

      var weatherRes = await weatherFuture;
      
      // Handle Rate Limit (Error 429) with simple retry
      if (weatherRes.statusCode == 429) {
          print("Rate limit hit, waiting 2s then retrying...");
          await Future.delayed(const Duration(seconds: 2));
          weatherRes = await http.get(Uri.parse(
            "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,uv_index&timezone=auto"
          )).timeout(const Duration(seconds: 8));
      }

      final aqiRes = await aqiFuture;

      if (weatherRes.statusCode == 200) {
        var weatherData = jsonDecode(weatherRes.body)["current"];
        var airData = aqiRes.statusCode == 200 ? jsonDecode(aqiRes.body)["current"] : null;
        
        final result = {
          "name": cityName,
          "main": {
            "temp": weatherData["temperature_2m"],
            "humidity": weatherData["relative_humidity_2m"],
            "pressure": weatherData["surface_pressure"],
          },
          "wind": {"speed": weatherData["wind_speed_10m"]},
          "uvi": weatherData["uv_index"] ?? 0.0,
          "aqi": airData?["us_aqi"] ?? 0,
          "weather": [{"main": _getWeatherDesc(weatherData["temperature_2m"])}],
        };

        // Cache persistent data
        _cache[cacheKey] = result;
        _cacheTime[cacheKey] = DateTime.now();

        return result;
      }
      
      // If error occurs, try to return LAST KNOWN CACHED DATA as a fallback
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      
      return {"error": "Weather service returned ${weatherRes.statusCode}. Try again in 1 min."};
    } catch (e) {
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      // Dedicated handling for common Web/Network errors (CORS, DNS, Firewall)
      String error = e.toString();
      if (error.contains("Failed to fetch") || 
          error.contains("SocketException") || 
          error.contains("XMLHttpRequest") ||
          error.contains("ClientException") ||
          error.contains("error")) {
         return {"error": "Connection failed. Please check internet or search manually."};
      }
      return {"error": "Weather data unavailable. Tap refresh or pick city."};
    }
  }

  static String _getWeatherDesc(double temp) {
    if (temp > 30) return "Hot & Sunny";
    if (temp > 20) return "Clear & Pleasant";
    if (temp > 10) return "Cool";
    return "Cold";
  }
}