/// Holds the active filter state for publication search results.
/// All fields are optional — null means "no filter applied" for that field.
class SearchFilter {
  final String? author;      // filter by author name (contains match)
  final int? yearFrom;       // filter by year >= yearFrom
  final int? yearTo;         // filter by year <= yearTo
  final String? journal;     // filter by journal name (contains match)
  final String? field;       // filter by research field/major

  const SearchFilter({
    this.author,
    this.yearFrom,
    this.yearTo,
    this.journal,
    this.field,
  });

  /// True if no filters are active.
  bool get isEmpty =>
      author == null &&
      yearFrom == null &&
      yearTo == null &&
      journal == null &&
      field == null;

  /// Number of active filters — used to show a badge on the filter button.
  int get activeCount {
    int count = 0;
    if (author != null && author!.isNotEmpty) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (journal != null && journal!.isNotEmpty) count++;
    if (field != null) count++;
    return count;
  }

  SearchFilter copyWith({
    Object? author = _sentinel,
    Object? yearFrom = _sentinel,
    Object? yearTo = _sentinel,
    Object? journal = _sentinel,
    Object? field = _sentinel,
  }) {
    return SearchFilter(
      author: author == _sentinel ? this.author : author as String?,
      yearFrom: yearFrom == _sentinel ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _sentinel ? this.yearTo : yearTo as int?,
      journal: journal == _sentinel ? this.journal : journal as String?,
      field: field == _sentinel ? this.field : field as String?,
    );
  }

  static const Object _sentinel = Object();

  /// Research fields/majors dropdown options.
  static const List<String> researchFields = [
    'Computer Science',
    'Medicine',
    'Physics',
    'Biology',
    'Chemistry',
    'Mathematics',
    'Engineering',
    'Psychology',
    'Economics',
    'Environmental Science',
    'Materials Science',
    'Neuroscience',
    'Political Science',
    'Sociology',
    'Linguistics',
    'Philosophy',
    'Education',
    'Law',
    'Business',
    'Art & Humanities',
  ];
}