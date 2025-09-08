import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static String? _cachedCountryCode;
  static String? _cachedCountryName;
  
  /// Get user's country code (simple and cached approach)
  static Future<String> getUserCountryCode() async {
    // Return cached value if available
    if (_cachedCountryCode != null) {
      return _cachedCountryCode!;
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        // Default to France if no permission
        _cachedCountryCode = 'FR';
        _cachedCountryName = 'France';
        return 'FR';
      }

      // Get current position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Low accuracy is fine for country
        timeLimit: const Duration(seconds: 10),
      );

      // Get country from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode ?? 'FR';
        final countryName = placemarks.first.country ?? 'France';
        
        // Cache the result
        _cachedCountryCode = countryCode;
        _cachedCountryName = countryName;
        
        return countryCode;
      }
      
    } catch (e) {
      print('Error getting location: $e');
    }

    // Default fallback
    _cachedCountryCode = 'FR';
    _cachedCountryName = 'France';
    return 'FR';
  }

  /// Get user's country name for display
  static Future<String> getUserCountryName() async {
    // Ensure country code is loaded
    await getUserCountryCode();
    return _cachedCountryName ?? 'France';
  }

  /// Get country-specific food context for AI
  static Future<String> getFoodCultureContext() async {
    final countryCode = await getUserCountryCode();
    
    // Return culture-specific context for common countries
    switch (countryCode) {
      case 'FR':
        return 'French cuisine and portion sizes';
      case 'US':
        return 'American cuisine and portion sizes';
      case 'IT':
        return 'Italian cuisine and portion sizes';
      case 'ES':
        return 'Spanish cuisine and portion sizes';
      case 'DE':
        return 'German cuisine and portion sizes';
      case 'GB':
        return 'British cuisine and portion sizes';
      case 'JP':
        return 'Japanese cuisine and portion sizes';
      case 'CN':
        return 'Chinese cuisine and portion sizes';
      case 'IN':
        return 'Indian cuisine and portion sizes';
      case 'MX':
        return 'Mexican cuisine and portion sizes';
      case 'BR':
        return 'Brazilian cuisine and portion sizes';
      case 'CA':
        return 'Canadian cuisine and portion sizes';
      case 'AU':
        return 'Australian cuisine and portion sizes';
      case 'RU':
        return 'Russian cuisine and portion sizes';
      case 'KR':
        return 'Korean cuisine and portion sizes';
      case 'TH':
        return 'Thai cuisine and portion sizes';
      case 'VN':
        return 'Vietnamese cuisine and portion sizes';
      case 'TR':
        return 'Turkish cuisine and portion sizes';
      case 'GR':
        return 'Greek cuisine and portion sizes';
      case 'MA':
        return 'Moroccan cuisine and portion sizes';
      case 'EG':
        return 'Egyptian cuisine and portion sizes';
      case 'NG':
        return 'Nigerian cuisine and portion sizes';
      case 'ZA':
        return 'South African cuisine and portion sizes';
      case 'AR':
        return 'Argentinian cuisine and portion sizes';
      case 'CL':
        return 'Chilean cuisine and portion sizes';
      case 'PE':
        return 'Peruvian cuisine and portion sizes';
      default:
        return 'International cuisine and standard portion sizes';
    }
  }

  /// Clear cached location data (useful for testing)
  static void clearCache() {
    _cachedCountryCode = null;
    _cachedCountryName = null;
  }
}