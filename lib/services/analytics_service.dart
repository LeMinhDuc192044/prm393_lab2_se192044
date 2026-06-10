import '../models/publication.dart';

class AnalyticsService {
  // Publications per year
  Map<int, int> publicationsByYear(List<Publication> pubs) {
    final map = <int, int>{};
    for (final p in pubs) {
      if (p.year > 0) {
        map[p.year] = (map[p.year] ?? 0) + 1;
      }
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  // Top N papers by citation
  List<Publication> topInfluentialPapers(List<Publication> pubs, {int top = 10}) {
    final sorted = [...pubs]..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    return sorted.take(top).toList();
  }

  // Top journals by publication count
  Map<String, int> topJournals(List<Publication> pubs, {int top = 10}) {
    final map = <String, int>{};
    for (final p in pubs) {
      final journal = p.journalName;
      if (journal != null && journal.isNotEmpty) {
        map[journal] = (map[journal] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(top));
  }

  // Top authors by publication count
  Map<String, int> topAuthors(List<Publication> pubs, {int top = 10}) {
    final map = <String, int>{};
    for (final p in pubs) {
      for (final author in p.authors) {
        if (author.name.isNotEmpty && author.name != 'Unknown Author') {
          map[author.name] = (map[author.name] ?? 0) + 1;
        }
      }
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(top));
  }

  // Dashboard summary
  DashboardSummary computeDashboard(List<Publication> pubs) {
    if (pubs.isEmpty) {
      return DashboardSummary(
        totalPublications: 0,
        avgCitations: 0,
        mostActiveYear: 0,
        topJournal: 'N/A',
        topAuthor: 'N/A',
        mostInfluentialPaper: null,
      );
    }

    final totalCitations = pubs.fold<int>(0, (sum, p) => sum + p.citationCount);
    final avgCitations = totalCitations / pubs.length;

    final byYear = publicationsByYear(pubs);
    final mostActiveYear = byYear.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final journals = topJournals(pubs, top: 1);
    final topJournal = journals.keys.firstOrNull ?? 'N/A';

    final authors = topAuthors(pubs, top: 1);
    final topAuthor = authors.keys.firstOrNull ?? 'N/A';

    final influential = topInfluentialPapers(pubs, top: 1);
    final mostInfluentialPaper = influential.firstOrNull;

    return DashboardSummary(
      totalPublications: pubs.length,
      avgCitations: avgCitations,
      mostActiveYear: mostActiveYear,
      topJournal: topJournal,
      topAuthor: topAuthor,
      mostInfluentialPaper: mostInfluentialPaper,
    );
  }
}

class DashboardSummary {
  final int totalPublications;
  final double avgCitations;
  final int mostActiveYear;
  final String topJournal;
  final String topAuthor;
  final Publication? mostInfluentialPaper;

  DashboardSummary({
    required this.totalPublications,
    required this.avgCitations,
    required this.mostActiveYear,
    required this.topJournal,
    required this.topAuthor,
    required this.mostInfluentialPaper,
  });
}