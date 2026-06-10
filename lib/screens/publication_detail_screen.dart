import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

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
        title: const Text('Publication Details'),
        actions: [
          if (publication.doi != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open DOI',
              onPressed: () {
                final doi = publication.doi!;
                final url = doi.startsWith('http') ? doi : 'https://doi.org/$doi';
                _launchUrl(url);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleCard(context),
            const SizedBox(height: 16),
            _buildMetaGrid(context),
            const SizedBox(height: 16),
            if (publication.authors.isNotEmpty) ...[
              _buildAuthorsCard(context),
              const SizedBox(height: 16),
            ],
            if (publication.abstract != null && publication.abstract!.isNotEmpty) ...[
              _buildAbstractCard(context),
              const SizedBox(height: 16),
            ],
            if (publication.doi != null) _buildDoiCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                publication.journalName ?? 'Unknown Journal',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(publication.title,
                style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }

  // ── Replaced GridView with Row+Column to avoid fixed-height overflow ─────────
  Widget _buildMetaGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _metaTile(
                icon: Icons.calendar_today,
                label: 'Year',
                value: publication.year > 0 ? '${publication.year}' : 'N/A',
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              _metaTile(
                icon: Icons.people,
                label: 'Authors',
                value: '${publication.authors.length}',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _metaTile(
                icon: Icons.format_quote,
                label: 'Citations',
                value: _formatNumber(publication.citationCount),
                color: AppTheme.accent,
              ),
              const SizedBox(height: 12),
              _metaTile(
                icon: Icons.description,
                label: 'Abstract',
                value: (publication.abstract != null &&
                        publication.abstract!.isNotEmpty)
                    ? 'Available'
                    : 'N/A',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Authors',
              subtitle: '${publication.authors.length} contributor(s)',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: publication.authors
                  .map((a) => Chip(
                        avatar: const CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child:
                              Icon(Icons.person, size: 14, color: Colors.white),
                        ),
                        label:
                            Text(a.name, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbstractCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Abstract'),
            const SizedBox(height: 12),
            Text(
              publication.abstract!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoiCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'DOI'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                final doi = publication.doi!;
                final url =
                    doi.startsWith('http') ? doi : 'https://doi.org/$doi';
                _launchUrl(url);
              },
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      publication.doi!,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}