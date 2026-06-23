import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';
import 'dashboard_screen.dart';

/// Single-screen Home with a persistent search bar at the top and a
/// TabBar below it that switches between Search / Trends / Dashboard
/// content in place — no Navigator.push, no screen transition.
/// The search bar stays visible on every tab so the user can search
/// again without switching back to the Search tab first.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journal Trend Analyzer'),
        ),
        body: Column(
          children: [
            // ── Persistent search bar — visible on every tab ──────────────
            _buildSearchHeader(),
            // ── Tab content swaps below the search bar ────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _buildSearchResultsTab(),
                  _buildTrendsTab(),
                  _buildDashboardTab(),
                ],
              ),
            ),
          ],
        ),
        // ── Search / Trends / Dashboard buttons live at the bottom ──────────
        bottomNavigationBar: Material(
          color: AppTheme.primary,
          child: SafeArea(
            top: false,
            child: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Trends'),
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Persistent Search Header ─────────────────────────────────────────────────
  Widget _buildSearchHeader() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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

  // ── Tab 1: Search Results (search bar lives above, outside this tab) ────────
  Widget _buildSearchResultsTab() {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        switch (provider.status) {
          case SearchStatus.idle:
            return const EmptyState(
              icon: Icons.search,
              title: 'Search Publications',
              subtitle:
                  'Enter a research topic above to explore publications, trends, and insights from OpenAlex.',
            );
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.surface,
          child: Row(
            children: [
              Icon(Icons.article_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${provider.publications.length} publications for "${provider.query}"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
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

  // ── Tab 2: Trends ────────────────────────────────────────────────────────────
  Widget _buildTrendsTab() {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        if (!provider.hasData) {
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No Trend Data Yet',
            subtitle: 'Use the search bar above to explore a topic first.',
          );
        }
        // TrendAnalysisBody has its own internal sub-tabs (By Year / Journals /
        // Papers / Authors), so it needs its own DefaultTabController.
        return const DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Material(
                color: AppTheme.primaryLight,
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(icon: Icon(Icons.show_chart), text: 'By Year'),
                    Tab(icon: Icon(Icons.library_books), text: 'Top Journals'),
                    Tab(icon: Icon(Icons.format_quote), text: 'Top Papers'),
                    Tab(icon: Icon(Icons.people), text: 'Top Authors'),
                  ],
                ),
              ),
              Expanded(child: TrendAnalysisBody()),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Dashboard ─────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        if (!provider.hasData) {
          return const EmptyState(
            icon: Icons.dashboard_outlined,
            title: 'No Dashboard Data Yet',
            subtitle: 'Use the search bar above to explore a topic first.',
          );
        }
        return const DashboardBody();
      },
    );
  }
}