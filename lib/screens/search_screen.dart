import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';
import 'dashboard_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Blockchain',
    'Internet of Things',
    'Cybersecurity',
    'Data Science',
    'Software Engineering',
    'Natural Language Processing',
    'Deep Learning',
    'Cloud Computing',
  ];

  void _search(String topic) {
    if (topic.trim().isEmpty) return;
    _controller.text = topic;
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(topic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        actions: [
          Consumer<SearchProvider>(
            builder: (_, provider, __) {
              if (!provider.hasData) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    tooltip: 'Trend Analysis',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const TrendAnalysisScreen(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.dashboard),
                    tooltip: 'Dashboard',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const DashboardScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search research topics...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _search(_controller.text),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => RawChip(
                label: Text(
                  _suggestions[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.white.withValues(alpha: .5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _search(_suggestions[i]),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        switch (provider.status) {
          case SearchStatus.idle:
            return _buildIdleState();
          case SearchStatus.loading:
            return const ShimmerList();
          case SearchStatus.error:
            return ErrorDisplay(
              message: provider.errorMessage,
              onRetry: () => provider.search(provider.query),
            );
          case SearchStatus.success:
            return _buildResults(provider);
        }
      },
    );
  }

  Widget _buildIdleState() {
    return const EmptyState(
      icon: Icons.search,
      title: 'Search Publications',
      subtitle:
          'Enter a research topic to explore publications, trends, and insights from OpenAlex.',
    );
  }

  Widget _buildResults(SearchProvider provider) {
    if (provider.publications.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'No Results',
        subtitle: 'No publications found for this topic. Try a different keyword.',
      );
    }

    return Column(
      children: [
        _buildResultsBar(provider),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.publications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final pub = provider.publications[i];
              return PublicationCard(
                publication: pub,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(publication: pub),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsBar(SearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${provider.publications.length} publications for "${provider.query}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.dashboard_outlined, size: 16),
            label: const Text('Dashboard'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const DashboardScreen(),
                ),
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.bar_chart_outlined, size: 16),
            label: const Text('Trends'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const TrendAnalysisScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}