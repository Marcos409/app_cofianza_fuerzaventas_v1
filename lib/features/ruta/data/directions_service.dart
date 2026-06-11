import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/utils/decode_polyline.dart';

class DirectionsService {
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required List<LatLng> waypoints,
    required LatLng destination,
  }) async {
    if (_apiKey.isEmpty) return null;

    final waypointsStr = waypoints
        .map((w) => '${w.latitude},${w.longitude}')
        .join('|');

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      if (waypoints.isNotEmpty) 'waypoints': waypointsStr,
      'mode': 'driving',
      'key': _apiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final overviewPolyline =
          route['overview_polyline'] as Map<String, dynamic>?;
      if (overviewPolyline == null) return null;

      final encoded = overviewPolyline['points'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      return decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }
}
