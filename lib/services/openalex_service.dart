import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/publication.dart';

// Top-level functions required by compute()
List<Publication> _parsePublications(String responseBody) {
  final data = json.decode(responseBody) as Map<String, dynamic>;
  final results = data['results'] as List<dynamic>? ?? [];
  return results
      .map((r) => Publication.fromJson(r as Map<String, dynamic>))
      .toList();
}

Publication _parsePublication(String responseBody) {
  final data = json.decode(responseBody) as Map<String, dynamic>;
  return Publication.fromJson(data);
}

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  static const String _email = 'student@university.edu';
  static const int _pageSize = 50;
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<Publication>> fetchPublications(String topic,
      {int maxPages = 2}) async {
    // Fetch pages concurrently
    final futures = List.generate(
      maxPages,
      (i) => _fetchPage(topic, i + 1),
    );
    final pages = await Future.wait(futures, eagerError: false);
    return pages.expand((p) => p).toList();
  }

  Future<List<Publication>> _fetchPage(String topic, int page) async {
    final uri = Uri.parse(
      '$_baseUrl/works'
      '?search=${Uri.encodeComponent(topic)}'
      '&filter=type:article'
      '&sort=cited_by_count:desc'
      '&per-page=$_pageSize'
      '&page=$page'
      '&select=id,display_name,publication_year,cited_by_count,'
      'authorships,primary_location,doi,abstract_inverted_index'
      '&mailto=$_email'
      '&api_key=R5pqp64tNZFP8u9S431c3w',
    );

    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      debugPrint('Request URL: $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      throw Exception(
        'HTTP ${response.statusCode}\n'
        'URL: $uri\n'
        'Body: ${response.body}',
      );
    }

    // compute() runs parsing in a background isolate without Dart 2.19 requirement
    return compute(_parsePublications, response.body);
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    for (int i = 0; i < delays.length; i++) {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        return response;
      }

      if (response.statusCode != 503) {
        throw Exception('HTTP ${response.statusCode}');
      }

      await Future.delayed(delays[i]);
    }

    throw Exception('HTTP 503');
  }

  Future<Publication?> fetchPublicationById(String id) async {
    final cleanId = id.split('/').last;
    final uri = Uri.parse('$_baseUrl/works/W$cleanId?mailto=$_email');

    final response = await _getWithRetry(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;

    return compute(_parsePublication, response.body);
  }
}