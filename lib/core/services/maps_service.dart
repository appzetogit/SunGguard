import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_environment.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? json['description'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }
}

class LocationDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? street;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;

  const LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.street,
    this.area,
    this.city,
    this.state,
    this.pincode,
  });
}

class MapsService {
  final Dio _dio;
  final String apiKey;

  MapsService({
    Dio? dio,
    this.apiKey = AppEnvironment.googleMapsApiKey,
  }) : _dio = dio ?? Dio();

  /// Search Places via Google Places Autocomplete API
  Future<List<PlacePrediction>> getPlacePredictions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': apiKey,
          'components': 'country:in',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final predictions = (response.data['predictions'] as List? ?? [])
            .map((item) => PlacePrediction.fromJson(item as Map<String, dynamic>))
            .toList();
        return predictions;
      }
    } catch (e) {
      debugPrint('❌ MapsService getPlacePredictions error: $e');
    }
    return [];
  }

  /// Reverse Geocode (Lat/Lng -> Formatted Address)
  Future<LocationDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final results = response.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final formatted = first['formatted_address'] as String? ?? '';
          final components = (first['address_components'] as List? ?? []);

          String? street;
          String? area;
          String? city;
          String? state;
          String? pincode;

          for (final comp in components) {
            final types = (comp['types'] as List? ?? []).cast<String>();
            final name = comp['long_name'] as String? ?? '';

            if (types.contains('route') || types.contains('street_number')) {
              street = name;
            } else if (types.contains('sublocality') || types.contains('neighborhood')) {
              area = name;
            } else if (types.contains('locality')) {
              city = name;
            } else if (types.contains('administrative_area_level_1')) {
              state = name;
            } else if (types.contains('postal_code')) {
              pincode = name;
            }
          }

          return LocationDetails(
            latitude: latitude,
            longitude: longitude,
            formattedAddress: formatted,
            street: street,
            area: area,
            city: city,
            state: state,
            pincode: pincode,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ MapsService reverseGeocode error: $e');
    }
    return null;
  }

  /// Forward Geocode (Place ID -> Lat/Lng & Details)
  Future<LocationDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'formatted_address,geometry,address_components',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['result'] as Map<String, dynamic>? ?? {};
        final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
        final location = geometry['location'] as Map<String, dynamic>? ?? {};
        final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;
        final formatted = result['formatted_address'] as String? ?? '';

        return LocationDetails(
          latitude: lat,
          longitude: lng,
          formattedAddress: formatted,
        );
      }
    } catch (e) {
      debugPrint('❌ MapsService getPlaceDetails error: $e');
    }
    return null;
  }

  static LocationDetails? cachedLocation;

  /// Auto-detect current device location via Hardware GPS Sensor (Cached)
  Future<LocationDetails?> fetchCurrentLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && cachedLocation != null) {
      return cachedLocation;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions are permanently denied');
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final reverseResult = await reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (reverseResult != null) {
        cachedLocation = reverseResult;
        return cachedLocation;
      }

      cachedLocation = LocationDetails(
        latitude: position.latitude,
        longitude: position.longitude,
        formattedAddress: 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
      );
      return cachedLocation;
    } catch (e) {
      debugPrint('❌ MapsService fetchCurrentLocation error: $e');
    }
    return cachedLocation;
  }

  /// Generate Google Static Map URL (Muted style without POIs like hospitals/parks)
  String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 600,
    int height = 300,
  }) {
    const styleParams =
        '&style=feature:poi%7Cvisibility:off&style=feature:transit%7Cvisibility:simplified';
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=$zoom&size=${width}x$height&markers=color:red%7C$latitude,$longitude$styleParams&key=$apiKey';
  }

  /// Decode an Encoded Polyline String into a list of [LatLng] coordinates
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.trim().isEmpty) return [];
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    try {
      while (index < len) {
        int b;
        int shift = 0;
        int result = 0;
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.add(LatLng(lat / 1E5, lng / 1E5));
      }
    } catch (e) {
      debugPrint('❌ MapsService decodePolyline error: $e');
    }
    return points;
  }

  /// Fetch directions polyline points between origin and destination via Google Directions API
  Future<List<LatLng>> fetchDirectionsPolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final routes = response.data['routes'] as List? ?? [];
        if (routes.isNotEmpty) {
          final overviewPolyline = routes.first['overview_polyline'] as Map<String, dynamic>? ?? {};
          final pointsString = overviewPolyline['points'] as String? ?? '';
          if (pointsString.isNotEmpty) {
            return decodePolyline(pointsString);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ MapsService fetchDirectionsPolyline error: $e');
    }
    return [origin, destination];
  }

  /// Calculate bearing / heading angle in degrees (0..360) between start and end LatLng
  static double calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (math.pi / 180.0);
    final startLng = start.longitude * (math.pi / 180.0);
    final endLat = end.latitude * (math.pi / 180.0);
    final endLng = end.longitude * (math.pi / 180.0);

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearing = math.atan2(y, x) * (180.0 / math.pi);
    return (bearing + 360.0) % 360.0;
  }

  /// Linearly interpolate between start and end LatLng by fraction t (0.0 to 1.0)
  static LatLng lerpLatLng(LatLng start, LatLng end, double t) {
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lng = start.longitude + (end.longitude - start.longitude) * t;
    return LatLng(lat, lng);
  }
}
