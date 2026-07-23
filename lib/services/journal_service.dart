import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/journal.dart';

class JournalService {
  static const String _email = 'student@university.edu';
  static const Duration _timeout = Duration(seconds: 15);

  static const String _sourceSelect =
      'id,display_name,issn_l,issn,homepage_url,works_count,'
      'cited_by_count,type,country_code,is_oa,apc_usd,'
      'host_organization_name,topics';

  /// Search journals/sources by name keyword.
  Future<List<Journal>> searchJournals(String query, {int perPage = 20}) async {
    final uri = Uri.https('api.openalex.org', '/sources', {
      'search': query,
      'filter': 'type:journal',
      'sort': 'works_count:desc',
      'per-page': '$perPage',
      'select': _sourceSelect,
      'mailto': _email,
    });

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => Journal.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single journal by its OpenAlex source ID.
  Future<Journal?> fetchJournalById(String sourceId) async {
    // Accept full URL or bare ID like S123456789
    final cleanId = sourceId.startsWith('https')
        ? sourceId.split('/').last
        : sourceId;

    final uri = Uri.https('api.openalex.org', '/sources/$cleanId', {
      'select': _sourceSelect,
      'mailto': _email,
    });

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    return Journal.fromJson(data);
  }

  /// Fetch recent articles published in a journal, grouped by year (volume proxy).
  /// OpenAlex doesn't expose volume numbers directly, so we group by year.
  Future<Map<int, List<JournalArticle>>> fetchRecentArticles(
    String sourceId, {
    int years = 5,
  }) async {
    final cleanId = sourceId.startsWith('https')
        ? sourceId.split('/').last
        : sourceId;

    final currentYear = DateTime.now().year;
    final fromYear = currentYear - years;

    final uri = Uri.https('api.openalex.org', '/works', {
      'filter': 'primary_location.source.id:$cleanId,publication_year:>$fromYear',
      'sort': 'publication_year:desc',
      'per-page': '50',
      'select': 'id,display_name,publication_year,cited_by_count,authorships',
      'mailto': _email,
    });

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    final articles = results
        .map((r) => JournalArticle.fromJson(r as Map<String, dynamic>))
        .toList();

    // Group by year (year acts as a volume proxy)
    final Map<int, List<JournalArticle>> grouped = {};
    for (final article in articles) {
      grouped.putIfAbsent(article.year, () => []).add(article);
    }

    // Sort years descending
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  /// Fetch journals that a publication's source belongs to — used to
  /// link a publication to its journal detail page.
  Future<Journal?> fetchJournalForSource(String sourceId) async {
    return fetchJournalById(sourceId);
  }
}
