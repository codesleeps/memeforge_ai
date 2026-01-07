import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching images from Unsplash API
class UnsplashService {
  static final UnsplashService _instance = UnsplashService._internal();
  factory UnsplashService() => _instance;
  UnsplashService._internal();

  static const String accessKey = '9zuLVNwmOC37RcHLVTPcbzLB6e_A3iYKiipnkkEUOZY';
  static const String baseUrl = 'https://api.unsplash.com';

  /// Search for photos by query
  Future<String?> searchPhoto(
    String query, {
    int page = 1,
    int perPage = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search/photos').replace(
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'per_page': perPage.toString(),
          'orientation': 'squarish',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Client-ID $accessKey',
          'Accept-Version': 'v1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          // Return regular size image URL
          return results[0]['urls']['regular'] as String;
        }
      }

      return null;
    } catch (e) {
      print('Unsplash search error: $e');
      return null;
    }
  }

  /// Get a random photo by query
  Future<String?> getRandomPhoto(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/photos/random').replace(
        queryParameters: {
          'query': query,
          'orientation': 'squarish',
          'count': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Client-ID $accessKey',
          'Accept-Version': 'v1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle both single object and array responses
        if (data is List && data.isNotEmpty) {
          return data[0]['urls']['regular'] as String;
        } else if (data is Map) {
          return data['urls']['regular'] as String;
        }
      }

      return null;
    } catch (e) {
      print('Unsplash random photo error: $e');
      return null;
    }
  }
}
