import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart';

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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journal Trend Analyzer'),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              icon: const Icon(Icons.account_circle_outlined),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthViewModel>().signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildUserHeader(context),
            // ── Persistent search bar — visible on Search/Trends/Dashboard ──
            _buildSearchHeader(),
            // ── Tab content swaps below the search bar ────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _buildSearchResultsTab(),
                  _buildTrendsTab(),
                  _buildDashboardTab(),
                  const JournalScreen(),
                ],
              ),
            ),
          ],
        ),
        // ── Bottom tab bar ────────────────────────────────────────────────────
        bottomNavigationBar: const Material(
          color: AppTheme.primary,
          child: SafeArea(
            top: false,
            child: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Trends'),
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                Tab(icon: Icon(Icons.library_books), text: 'Journals'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Persistent Search Header ─────────────────────────────────────────────────
  Widget _buildUserHeader(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final provider = user.providerData.isEmpty
        ? 'password'
        : user.providerData.first.providerId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.photoURL == null ? null : NetworkImage(user.photoURL!),
            child: user.photoURL == null
                ? const Icon(Icons.person_outline)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!
                      : 'Signed-in user',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(user.email ?? '', style: const TextStyle(fontSize: 12)),
                Text(
                  'Provider: $provider  |  UID: ${user.uid}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        subtitle:
            'No publications found for this topic. Try a different keyword.',
      );
    }

    final filtered = provider.filteredPublications;
    final filterCount = provider.filter.activeCount;

    return Column(
      children: [
        // ── Results bar with filter button ───────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          color: AppTheme.surface,
          child: Row(
            children: [
              const Icon(Icons.article_outlined,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  filterCount > 0
                      ? '${filtered.length} of ${provider.publications.length} publications'
                      : '${provider.publications.length} publications for "${provider.query}"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // Filter button with active-filter badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: filterCount > 0
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    tooltip: 'Filter',
                    onPressed: () => showFilterSheet(context),
                  ),
                  if (filterCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Clear filter button
              if (filterCount > 0)
                TextButton(
                  onPressed: provider.clearFilter,
                  child: const Text('Clear',
                      style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
            ],
          ),
        ),
        // ── Active filter chips ──────────────────────────────────────────
        if (filterCount > 0) _buildActiveFilterChips(provider),
        // ── Results list ─────────────────────────────────────────────────
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No Matches',
              subtitle:
                  'No publications match the current filters. Try adjusting or clearing them.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final pub = filtered[i];
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

  Widget _buildActiveFilterChips(SearchProvider provider) {
    final filter = provider.filter;
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (filter.author != null && filter.author!.isNotEmpty)
            _filterChip('Author: ${filter.author}',
                () => provider.applyFilter(filter.copyWith(author: null))),
          if (filter.yearFrom != null || filter.yearTo != null)
            _filterChip(
              'Year: ${filter.yearFrom ?? '...'} – ${filter.yearTo ?? '...'}',
              () => provider
                  .applyFilter(filter.copyWith(yearFrom: null, yearTo: null)),
            ),
          if (filter.journal != null && filter.journal!.isNotEmpty)
            _filterChip('Journal: ${filter.journal}',
                () => provider.applyFilter(filter.copyWith(journal: null))),
          if (filter.field != null)
            _filterChip('Field: ${filter.field}',
                () => provider.applyFilter(filter.copyWith(field: null))),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
      deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primary),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
