class Publication {
  final String id;
  final String title;
  final int year;
  final int citationCount;
  final String? journalName;
  final String? doi;
  final String? abstract;
  final List<Author> authors;

  Publication({
    required this.id,
    required this.title,
    required this.year,
    required this.citationCount,
    this.journalName,
    this.doi,
    this.abstract,
    required this.authors,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    // Parse authors
    final authorships = json['authorships'] as List<dynamic>? ?? [];
    final authors = authorships
        .map((a) {
          final authorData = a['author'] as Map<String, dynamic>?;
          if (authorData == null) return null;
          return Author(
            id: authorData['id'] ?? '',
            name: authorData['display_name'] ?? 'Unknown Author',
          );
        })
        .whereType<Author>()
        .toList();

    // Parse journal name
    String? journalName;
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    if (primaryLocation != null) {
      final source = primaryLocation['source'] as Map<String, dynamic>?;
      journalName = source?['display_name'];
    }

    // Parse abstract from abstract_inverted_index
    String? abstract;
    final invertedIndex = json['abstract_inverted_index'] as Map<String, dynamic>?;
    if (invertedIndex != null) {
      abstract = _reconstructAbstract(invertedIndex);
    }

    return Publication(
      id: json['id'] ?? '',
      title: json['display_name'] ?? json['title'] ?? 'Untitled',
      year: json['publication_year'] ?? 0,
      citationCount: json['cited_by_count'] ?? 0,
      journalName: journalName,
      doi: json['doi'],
      abstract: abstract,
      authors: authors,
    );
  }

  static String _reconstructAbstract(Map<String, dynamic> invertedIndex) {
    final wordPositions = <int, String>{};
    invertedIndex.forEach((word, positions) {
      if (positions is List) {
        for (final pos in positions) {
          wordPositions[pos as int] = word;
        }
      }
    });
    final sortedPositions = wordPositions.keys.toList()..sort();
    return sortedPositions.map((pos) => wordPositions[pos]).join(' ');
  }
}

class Author {
  final String id;
  final String name;

  Author({required this.id, required this.name});
}