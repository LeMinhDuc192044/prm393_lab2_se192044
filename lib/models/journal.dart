class Journal {
  final String id;
  final String displayName;
  final String? issnL;
  final List<String> issns;
  final String? homepageUrl;
  final int worksCount;
  final int citedByCount;
  final String? type;
  final String? countryCode;
  final bool isOa;
  final int? apcUsd;
  final String? publisherName;
  final List<JournalTopic> topics;
 
  Journal({
    required this.id,
    required this.displayName,
    this.issnL,
    required this.issns,
    this.homepageUrl,
    required this.worksCount,
    required this.citedByCount,
    this.type,
    this.countryCode,
    required this.isOa,
    this.apcUsd,
    this.publisherName,
    required this.topics,
  });
 
  factory Journal.fromJson(Map<String, dynamic> json) {
    final issns = <String>[];
    if (json['issn'] is List) {
      issns.addAll((json['issn'] as List).map((e) => e.toString()));
    }
 
    final topics = <JournalTopic>[];
    if (json['topics'] is List) {
      for (final t in (json['topics'] as List)) {
        if (t is Map<String, dynamic>) {
          topics.add(JournalTopic.fromJson(t));
        }
      }
    }
 
    String? publisherName;
    if (json['host_organization_name'] != null) {
      publisherName = json['host_organization_name'] as String?;
    }
 
    return Journal(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown Journal',
      issnL: json['issn_l'] as String?,
      issns: issns,
      homepageUrl: json['homepage_url'] as String?,
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      type: json['type'] as String?,
      countryCode: json['country_code'] as String?,
      isOa: json['is_oa'] as bool? ?? false,
      apcUsd: json['apc_usd'] as int?,
      publisherName: publisherName,
      topics: topics,
    );
  }
 
  /// Returns the bare OpenAlex source ID (e.g. "S123456789").
  String get shortId => id.split('/').last;
}
 
class JournalTopic {
  final String id;
  final String displayName;
  final int count;
 
  JournalTopic({
    required this.id,
    required this.displayName,
    required this.count,
  });
 
  factory JournalTopic.fromJson(Map<String, dynamic> json) {
    return JournalTopic(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}
 
/// A recent work/article belonging to a journal, used in the
/// "recent articles in this journal" list.
class JournalArticle {
  final String id;
  final String title;
  final int year;
  final int citationCount;
  final List<String> authorNames;
 
  JournalArticle({
    required this.id,
    required this.title,
    required this.year,
    required this.citationCount,
    required this.authorNames,
  });
 
  factory JournalArticle.fromJson(Map<String, dynamic> json) {
    final authorships = json['authorships'] as List<dynamic>? ?? [];
    final names = authorships
        .map((a) {
          final author = a['author'] as Map<String, dynamic>?;
          return author?['display_name'] as String?;
        })
        .whereType<String>()
        .toList();
 
    return JournalArticle(
      id: json['id'] as String? ?? '',
      title: json['display_name'] as String? ?? json['title'] as String? ?? 'Untitled',
      year: json['publication_year'] as int? ?? 0,
      citationCount: json['cited_by_count'] as int? ?? 0,
      authorNames: names,
    );
  }
}