import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/journal.dart';
import '../services/journal_service.dart';
import '../services/profile_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class JournalDetailScreen extends StatefulWidget {
  /// Pass either a full [Journal] object (already loaded) or just an [sourceId]
  /// to load from the API.
  final Journal? journal;
  final String? sourceId;
  final String? journalName; // shown while loading

  const JournalDetailScreen({
    super.key,
    this.journal,
    this.sourceId,
    this.journalName,
  }) : assert(journal != null || sourceId != null,
            'Provide either journal or sourceId');

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  final _service = JournalService();
  final _profileService = ProfileService();

  Journal? _journal;
  Map<int, List<JournalArticle>> _articlesByYear = {};
  bool _loadingJournal = false;
  bool _loadingArticles = false;
  String? _error;
  int? _expandedYear;

  @override
  void initState() {
    super.initState();
    if (widget.journal != null) {
      _journal = widget.journal;
      _loadArticles(_journal!.id);
    } else {
      _loadJournal();
    }
  }

  Future<void> _loadJournal() async {
    setState(() => _loadingJournal = true);
    try {
      final j = await _service.fetchJournalById(widget.sourceId!);
      if (mounted) {
        setState(() {
          _journal = j;
          _loadingJournal = false;
        });
        if (j != null) _loadArticles(j.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingJournal = false;
        });
      }
    }
  }

  Future<void> _loadArticles(String sourceId) async {
    setState(() => _loadingArticles = true);
    try {
      final articles = await _service.fetchRecentArticles(sourceId, years: 5);
      if (mounted) {
        setState(() {
          _articlesByYear = articles;
          _loadingArticles = false;
          // Auto-expand the most recent year
          if (articles.isNotEmpty) _expandedYear = articles.keys.first;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingArticles = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _journal?.displayName ?? widget.journalName ?? 'Journal Detail',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_journal != null && FirebaseAuth.instance.currentUser != null)
            StreamBuilder(
              stream: _profileService.favoriteJournalStream(FirebaseAuth.instance.currentUser!.uid, _journal!.id),
              builder: (context, snapshot) {
                final saved = snapshot.data?.exists == true;
                return IconButton(
                  tooltip: saved ? 'Unfavorite journal' : 'Favorite journal',
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => _profileService.toggleFavoriteJournal(
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    journalId: _journal!.id,
                    data: {
                      'displayName': _journal!.displayName,
                      'publisher': _journal!.publisherName ?? '',
                      'country': _journal!.countryCode ?? '',
                    },
                  ),
                );
              },
            ),
          if (_journal?.homepageUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open website',
              onPressed: () => _launchUrl(_journal!.homepageUrl!),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingJournal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorDisplay(
        message: _error!,
        onRetry: _loadJournal,
      );
    }
    if (_journal == null) {
      return const EmptyState(
        icon: Icons.library_books_outlined,
        title: 'Journal Not Found',
        subtitle: 'Could not load details for this journal.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          if (_journal!.topics.isNotEmpty) ...[
            _buildTopicsCard(),
            const SizedBox(height: 16),
          ],
          _buildArticlesSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Header Card ──────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    final j = _journal!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + OA badge
            Row(
              children: [
                if (j.type != null)
                  _badge(j.type!.toUpperCase(), AppTheme.primary),
                if (j.isOa) ...[
                  const SizedBox(width: 8),
                  _badge('OPEN ACCESS', AppTheme.accent),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(j.displayName,
                style: Theme.of(context).textTheme.headlineMedium),
            if (j.publisherName != null) ...[
              const SizedBox(height: 6),
              Text(j.publisherName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      )),
            ],
            const SizedBox(height: 12),
            if (j.issnL != null)
              _infoRow(Icons.tag, 'ISSN-L', j.issnL!),
            if (j.issns.isNotEmpty)
              _infoRow(Icons.numbers, 'ISSNs', j.issns.join(', ')),
            if (j.countryCode != null)
              _infoRow(Icons.public, 'Country', j.countryCode!),
            if (j.apcUsd != null)
              _infoRow(Icons.attach_money, 'APC',
                  '\$${j.apcUsd} USD'),
            if (j.homepageUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _launchUrl(j.homepageUrl!),
                child: Row(
                  children: [
                    const Icon(Icons.link,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        j.homepageUrl!,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final j = _journal!;
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.article_outlined,
            label: 'Total Works',
            value: _fmt(j.worksCount),
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            icon: Icons.format_quote_outlined,
            label: 'Total Citations',
            value: _fmt(j.citedByCount),
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Topics Card ──────────────────────────────────────────────────────────────
  Widget _buildTopicsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Research Topics',
              subtitle: 'Main fields covered by this journal',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _journal!.topics.take(12).map((t) {
                return Chip(
                  label: Text(t.displayName,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor:
                      AppTheme.primary.withValues(alpha: 0.07),
                  side: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Articles by Year (Volume proxy) ───────────────────────────────────
  Widget _buildArticlesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Recent Volumes',
              subtitle: 'Articles from the last 5 years grouped by year',
            ),
            const SizedBox(height: 12),
            if (_loadingArticles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_articlesByYear.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No recent articles found.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              )
            else
              ..._articlesByYear.entries.map((entry) {
                final year = entry.key;
                final articles = entry.value;
                final isExpanded = _expandedYear == year;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year header — tap to expand/collapse
                    InkWell(
                      onTap: () => setState(() =>
                          _expandedYear = isExpanded ? null : year),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppTheme.primary.withValues(alpha: 0.08)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Volume $year',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isExpanded
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${articles.length} articles',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Articles list — shown when expanded
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      ...articles.map((a) => _articleTile(a)),
                    ],
                    const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _articleTile(JournalArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (article.authorNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              article.authorNames.take(3).join(', ') +
                  (article.authorNames.length > 3 ? ' et al.' : ''),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.format_quote_outlined,
                  size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${article.citationCount} citations',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
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
