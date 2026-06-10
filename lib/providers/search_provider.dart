import 'package:flutter/foundation.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../services/analytics_service.dart';

enum SearchStatus { idle, loading, success, error }

class SearchProvider extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();
  final AnalyticsService _analytics = AnalyticsService();

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  String _errorMessage = '';
  List<Publication> _publications = [];

  // Cached analytics — only recomputed when publications change
  Map<int, int>? _cachedByYear;
  List<Publication>? _cachedTopPapers;
  Map<String, int>? _cachedTopJournals;
  Map<String, int>? _cachedTopAuthors;
  DashboardSummary? _cachedDashboard;

  SearchStatus get status => _status;
  String get query => _query;
  String get errorMessage => _errorMessage;
  List<Publication> get publications => _publications;
  bool get hasData => _publications.isNotEmpty;

  Map<int, int> get publicationsByYear =>
      _cachedByYear ??= _analytics.publicationsByYear(_publications);

  List<Publication> get topInfluentialPapers =>
      _cachedTopPapers ??= _analytics.topInfluentialPapers(_publications);

  Map<String, int> get topJournals =>
      _cachedTopJournals ??= _analytics.topJournals(_publications);

  Map<String, int> get topAuthors =>
      _cachedTopAuthors ??= _analytics.topAuthors(_publications);

  DashboardSummary get dashboardSummary =>
      _cachedDashboard ??= _analytics.computeDashboard(_publications);

  Future<void> search(String topic) async {
    if (topic.trim().isEmpty) return;

    _query = topic.trim();
    _status = SearchStatus.loading;
    _publications = [];
    _clearCache();
    _errorMessage = '';
    notifyListeners();

    try {
      // maxPages: 2 pages × 50 results = 100 total — enough for all analytics
      final results =
          await _apiService.fetchPublications(_query, maxPages: 2);
      _publications = results;
      _status = SearchStatus.success;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  void _clearCache() {
    _cachedByYear = null;
    _cachedTopPapers = null;
    _cachedTopJournals = null;
    _cachedTopAuthors = null;
    _cachedDashboard = null;
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timeout')) {
      return 'Request timed out. The server may be slow — please retry.';
    }
    if (raw.contains('404')) return 'No results found for this topic.';
    if (raw.contains('429')) return 'Too many requests. Please wait a moment and retry.';
    return 'Failed to load data. Please try again.';
  }

  void reset() {
    _status = SearchStatus.idle;
    _query = '';
    _publications = [];
    _errorMessage = '';
    _clearCache();
    notifyListeners();
  }
}