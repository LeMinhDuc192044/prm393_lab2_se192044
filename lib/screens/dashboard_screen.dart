import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../services/analytics_service.dart';
import '../models/publication.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final summary = provider.dashboardSummary;
    final topAuthors = provider.topAuthors;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard: ${provider.query}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Overview header ─────────────────────────────────────────────
            _OverviewHeader(query: provider.query, summary: summary),
            const SizedBox(height: 16),

            // ── Key Metrics grid ────────────────────────────────────────────
            const SectionHeader(
              title: 'Key Metrics',
              subtitle: 'Summary statistics for the selected topic',
            ),
            const SizedBox(height: 12),
            _MetricsGrid(summary: summary),
            const SizedBox(height: 24),

            // ── Most Influential Paper ───────────────────────────────────────
            if (summary.mostInfluentialPaper != null) ...[
              const SectionHeader(
                title: 'Most Influential Paper',
                subtitle: 'Highest citation count in this dataset',
              ),
              const SizedBox(height: 12),
              _HighlightPaperCard(
                publication: summary.mostInfluentialPaper!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(
                      publication: summary.mostInfluentialPaper!,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Top Journal & Top Author highlights ──────────────────────────
            const SectionHeader(
              title: 'Top Highlights',
              subtitle: 'Leading journal and author for this topic',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.library_books_outlined,
                    label: 'Top Journal',
                    value: summary.topJournal,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.person_outline,
                    label: 'Top Author',
                    value: summary.topAuthor,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Top Contributing Authors ─────────────────────────────────────
            if (topAuthors.isNotEmpty) ...[
              const SectionHeader(
                title: 'Top Contributing Authors',
                subtitle: 'By number of publications in this topic',
              ),
              const SizedBox(height: 12),
              _TopAuthorsCard(topAuthors: topAuthors),
              const SizedBox(height: 24),
            ],

            // ── Quick Insight ────────────────────────────────────────────────
            _QuickInsightCard(summary: summary),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Overview header banner ────────────────────────────────────────────────────
class _OverviewHeader extends StatelessWidget {
  final String query;
  final DashboardSummary summary;

  const _OverviewHeader({required this.query, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Research Dashboard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      query,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(context, '${summary.totalPublications}', 'Publications'),
              _divider(),
              _headerStat(context,
                  summary.avgCitations.toStringAsFixed(1), 'Avg Citations'),
              _divider(),
              _headerStat(context,
                  summary.mostActiveYear > 0
                      ? '${summary.mostActiveYear}'
                      : 'N/A',
                  'Peak Year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withOpacity(0.25),
      );
}

// ── Key Metrics grid ──────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final DashboardSummary summary;

  const _MetricsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          label: 'Total Publications',
          value: '${summary.totalPublications}',
          icon: Icons.article_outlined,
          color: AppTheme.primary,
        ),
        StatCard(
          label: 'Avg Citations',
          value: summary.avgCitations.toStringAsFixed(1),
          icon: Icons.format_quote_outlined,
          color: AppTheme.accent,
        ),
        StatCard(
          label: 'Most Active Year',
          value: summary.mostActiveYear > 0 ? '${summary.mostActiveYear}' : 'N/A',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFFF59E0B),
        ),
        StatCard(
          label: 'Top Journal',
          value: summary.topJournal,
          icon: Icons.library_books_outlined,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

// ── Highlight paper card ──────────────────────────────────────────────────────
class _HighlightPaperCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const _HighlightPaperCard({required this.publication, required this.onTap});

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.emoji_events_outlined,
                            size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          'Most Cited',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_quote_outlined,
                            size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(publication.citationCount),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                publication.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (publication.journalName != null) ...[
                const SizedBox(height: 6),
                Text(
                  publication.journalName!,
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
                  if (publication.year > 0) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${publication.year}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (publication.authors.isNotEmpty) ...[
                    const Icon(Icons.person_outline,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        publication.authors.map((a) => a.name).take(3).join(', '),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Highlight card (journal / author) ────────────────────────────────────────
class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HighlightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ── Top Authors card ──────────────────────────────────────────────────────────
class _TopAuthorsCard extends StatelessWidget {
  final Map<String, int> topAuthors;

  const _TopAuthorsCard({required this.topAuthors});

  @override
  Widget build(BuildContext context) {
    final entries = topAuthors.entries.toList();
    final maxVal = entries.first.value.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...entries.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              final pct = entry.value / maxVal;
              final color = AppTheme.chartPalette[i % AppTheme.chartPalette.length];

              return Padding(
                padding: EdgeInsets.only(bottom: i < entries.length - 1 ? 14 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // rank badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: i < 3
                                ? color.withOpacity(0.15)
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: i < 3 ? color : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value} paper${entry.value != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Quick Insight card ────────────────────────────────────────────────────────
class _QuickInsightCard extends StatelessWidget {
  final DashboardSummary summary;

  const _QuickInsightCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Insight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _buildInsight(),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.6, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInsight() {
    if (summary.totalPublications == 0) return 'No data available.';

    final parts = <String>[];
    parts.add(
        'This dataset contains ${summary.totalPublications} publications with an average of ${summary.avgCitations.toStringAsFixed(1)} citations each.');

    if (summary.mostActiveYear > 0) {
      parts.add(
          '${summary.mostActiveYear} was the most active year for this research area.');
    }

    if (summary.topJournal != 'N/A') {
      parts.add(
          '"${summary.topJournal}" leads as the top contributing journal.');
    }

    if (summary.topAuthor != 'N/A') {
      parts.add(
          '${summary.topAuthor} is the most prolific author in this topic.');
    }

    return parts.join(' ');
  }
}