import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'journal_detail_screen.dart';

/// Journals tab — shows journals related to the current search query.
/// No separate search bar; driven by the shared SearchProvider.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _filter = '';
  bool _sortByWorks = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        // No search done yet
        if (provider.status == SearchStatus.idle) {
          return const EmptyState(
            icon: Icons.library_books_outlined,
            title: 'No Search Yet',
            subtitle:
                'Use the search bar above to find publications — related journals will appear here automatically.',
          );
        }

        // Loading
        if (provider.journalStatus == SearchStatus.loading) {
          return const ShimmerList(count: 4);
        }

        // Empty
        if (provider.journals.isEmpty) {
          return EmptyState(
            icon: Icons.library_books_outlined,
            title: 'No Journals Found',
            subtitle:
                'No journals found for "${provider.query}". Try a different topic.',
          );
        }

        final journals = provider.journals.where((journal) {
          final query = _filter.trim().toLowerCase();
          return query.isEmpty ||
              journal.displayName.toLowerCase().contains(query) ||
              (journal.publisherName?.toLowerCase().contains(query) ?? false);
        }).toList()
          ..sort((a, b) => _sortByWorks
              ? b.worksCount.compareTo(a.worksCount)
              : b.citedByCount.compareTo(a.citedByCount));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                      labelText: 'Filter journals',
                    ),
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _sortByWorks,
                  onChanged: (value) => setState(() => _sortByWorks = value ?? true),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Works')),
                    DropdownMenuItem(value: false, child: Text('Citations')),
                  ],
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.surface,
              child: Row(
                children: [
                  const Icon(Icons.library_books_outlined,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                       '${journals.length} journals related to "${provider.query}"',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                 itemCount: journals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                   final journal = journals[i];
                  return _JournalCard(
                    journal: journal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            JournalDetailScreen(journal: journal),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Journal Card ──────────────────────────────────────────────────────────────
class _JournalCard extends StatelessWidget {
  final Journal journal;
  final VoidCallback onTap;

  const _JournalCard({required this.journal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      journal.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (journal.isOa) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OA',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              if (journal.publisherName != null) ...[
                const SizedBox(height: 4),
                Text(
                  journal.publisherName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _pill(Icons.article_outlined,
                      '${_fmt(journal.worksCount)} works'),
                  const SizedBox(width: 8),
                  _pill(Icons.format_quote_outlined,
                      '${_fmt(journal.citedByCount)} citations'),
                  if (journal.issnL != null) ...[
                    const SizedBox(width: 8),
                    _pill(Icons.tag, journal.issnL!),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
              if (journal.topics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: journal.topics.take(3).map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t.displayName,
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.primary)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
