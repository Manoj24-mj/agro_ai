import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Map<String, String>?> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 2. Handle permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // 3. Get coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      // 4. Reverse Geocode using Nominatim API (OpenStreetMap)
      // This works globally and doesn't require an API key.
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'AgroAIDoctorApp/1.0', // Required by Nominatim policy
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        return {
          'city': address['city'] ?? address['town'] ?? address['village'] ?? address['state_district'] ?? 'Unknown',
          'country': address['country'] ?? 'Unknown',
          'country_code': address['country_code']?.toString().toUpperCase() ?? '',
        };
      }
    } catch (e) {
      print("Location detection error: $e");
    }
    return null;
  }
}
