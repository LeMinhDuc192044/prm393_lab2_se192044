import 'package:flutter/foundation.dart';
import '../models/publication.dart';
import '../models/journal.dart';
import '../models/search_filter.dart';
import '../services/openalex_service.dart';
import '../services/analytics_service.dart';
import '../services/journal_service.dart';

enum SearchStatus { idle, loading, success, error }

class SearchProvider extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();
  final AnalyticsService _analytics = AnalyticsService();
  final JournalService _journalService = JournalService();

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  String _errorMessage = '';
  List<Publication> _publications = [];
  SearchFilter _filter = const SearchFilter();

  // Journal state — driven by the same query
  List<Journal> _journals = [];
  SearchStatus _journalStatus = SearchStatus.idle;

  // Cached analytics — only recomputed when publications change
  Map<int, int>? _cachedByYear;
  List<Publication>? _cachedTopPapers;
  Map<String, int>? _cachedTopJournals;
  Map<String, int>? _cachedTopAuthors;
  DashboardSummary? _cachedDashboard;

  SearchStatus get status => _status;
  String get query => _query;
  String get errorMessage => _errorMessage;
  SearchFilter get filter => _filter;

  // Journal getters
  List<Journal> get journals => _journals;
  SearchStatus get journalStatus => _journalStatus;

  /// All fetched publications (unfiltered).
  List<Publication> get publications => _publications;

  /// Publications after applying the active filter — use this in the UI.
  List<Publication> get filteredPublications {
    if (_filter.isEmpty) return _publications;
    return _publications.where((p) {
      // Author filter — case-insensitive contains match on any author name
      if (_filter.author != null && _filter.author!.isNotEmpty) {
        final query = _filter.author!.toLowerCase();
        final match = p.authors.any(
          (a) => a.name.toLowerCase().contains(query),
        );
        if (!match) return false;
      }

      // Year range filter
      if (_filter.yearFrom != null && p.year < _filter.yearFrom!) return false;
      if (_filter.yearTo != null && p.year > _filter.yearTo!) return false;

      // Journal filter — case-insensitive contains match
      if (_filter.journal != null && _filter.journal!.isNotEmpty) {
        final journalName = p.journalName?.toLowerCase() ?? '';
        if (!journalName.contains(_filter.journal!.toLowerCase())) return false;
      }

      // Field filter — matches against journal name and title as a proxy
      // (OpenAlex doesn't return a subject field in our current select params)
      if (_filter.field != null) {
        final fieldLower = _filter.field!.toLowerCase();
        final titleMatch = p.title.toLowerCase().contains(fieldLower);
        final journalMatch =
            p.journalName?.toLowerCase().contains(fieldLower) ?? false;
        if (!titleMatch && !journalMatch) return false;
      }

      return true;
    }).toList();
  }

  bool get hasData => _publications.isNotEmpty;

  /// Unique author names from current results — used to populate filter suggestions.
  List<String> get availableAuthors {
    final names = <String>{};
    for (final p in _publications) {
      for (final a in p.authors) {
        if (a.name.isNotEmpty) names.add(a.name);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  /// Unique journal names from current results.
  List<String> get availableJournals {
    final names = <String>{};
    for (final p in _publications) {
      if (p.journalName != null && p.journalName!.isNotEmpty) {
        names.add(p.journalName!);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  /// Minimum year for the filter slider — always start from 1990
  /// regardless of what years are in the current result set.
  int get minYear => 1990;

  /// Maximum year for the filter slider — always the current year.
  int get maxYear => DateTime.now().year;

  // Analytics operate on filteredPublications so charts update with filters
  Map<int, int> get publicationsByYear =>
      _cachedByYear ??= _analytics.publicationsByYear(filteredPublications);

  List<Publication> get topInfluentialPapers =>
      _cachedTopPapers ??= _analytics.topInfluentialPapers(filteredPublications);

  Map<String, int> get topJournals =>
      _cachedTopJournals ??= _analytics.topJournals(filteredPublications);

  Map<String, int> get topAuthors =>
      _cachedTopAuthors ??= _analytics.topAuthors(filteredPublications);

  DashboardSummary get dashboardSummary =>
      _cachedDashboard ??= _analytics.computeDashboard(filteredPublications);

  /// Apply a new filter — clears analytics cache so charts update.
  void applyFilter(SearchFilter newFilter) {
    _filter = newFilter;
    _clearCache();
    notifyListeners();
  }

  /// Clear all filters.
  void clearFilter() {
    _filter = const SearchFilter();
    _clearCache();
    notifyListeners();
  }

  Future<void> search(String topic) async {
    if (topic.trim().isEmpty) return;

    _query = topic.trim();
    _status = SearchStatus.loading;
    _journalStatus = SearchStatus.loading;
    _publications = [];
    _journals = [];
    _filter = const SearchFilter();
    _clearCache();
    _errorMessage = '';
    notifyListeners();

    // Fetch publications and journals in parallel
    await Future.wait([
      _fetchPublications(),
      _fetchJournals(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchPublications() async {
    try {
      debugPrint('SearchProvider: fetching publications for "$_query"');
      List<Publication> results =
          await _apiService.fetchPublications(_query, maxPages: 2);

      if (results.isEmpty) {
        debugPrint('SearchProvider: empty result, retrying after 1s...');
        await Future.delayed(const Duration(seconds: 1));
        results = await _apiService.fetchPublications(_query, maxPages: 2);
      }

      debugPrint('SearchProvider: got ${results.length} publications');
      _publications = results;
      _status = SearchStatus.success;
    } catch (e) {
      debugPrint('SearchProvider: publications ERROR — $e');
      _errorMessage = _friendlyError(e.toString());
      _status = SearchStatus.error;
    }
  }

  Future<void> _fetchJournals() async {
    try {
      debugPrint('SearchProvider: fetching journals for "$_query"');
      final results = await _journalService.searchJournals(_query);
      debugPrint('SearchProvider: got ${results.length} journals');
      _journals = results;
      _journalStatus = SearchStatus.success;
    } catch (e) {
      debugPrint('SearchProvider: journals ERROR — $e');
      _journalStatus = SearchStatus.error;
    }
  }

  void _clearCache() {
    _cachedByYear = null;
    _cachedTopPapers = null;
    _cachedTopJournals = null;
    _cachedTopAuthors = null;
    _cachedDashboard = null;
  }

  String _friendlyError(String raw) {
    debugPrint('SearchProvider: raw error = $raw');
    if (raw.contains('SocketException') || raw.contains('Connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timeout')) {
      return 'Request timed out. The server may be slow — please retry.';
    }
    if (raw.contains('503')) {
      return 'OpenAlex server is temporarily unavailable. Please try again in a moment.';
    }
    if (raw.contains('429')) {
      return 'Too many requests. Please wait a moment and retry.';
    }
    if (kDebugMode) return 'Error: $raw';
    return 'Failed to load data. Please try again.';
  }

  void reset() {
    _status = SearchStatus.idle;
    _journalStatus = SearchStatus.idle;
    _query = '';
    _publications = [];
    _journals = [];
    _filter = const SearchFilter();
    _errorMessage = '';
    _clearCache();
    notifyListeners();
  }
}