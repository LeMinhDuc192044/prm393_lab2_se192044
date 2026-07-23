import 'package:flutter_test/flutter_test.dart';

import 'package:prm393_lab2_se192044/models/publication.dart';

void main() {
  test('parses an OpenAlex publication for bookmark actions', () {
    final publication = Publication.fromJson({
      'id': 'https://openalex.org/W1',
      'display_name': 'Test paper',
      'publication_year': 2024,
      'cited_by_count': 3,
      'authorships': [],
    });

    expect(publication.id, 'https://openalex.org/W1');
    expect(publication.title, 'Test paper');
    expect(publication.year, 2024);
  });
}
