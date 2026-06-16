import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/search_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'publication_detail_screen.dart';


class TrendAnalysisScreen extends StatelessWidget {
  const TrendAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Trends: ${provider.query}'),
          bottom: const TabBar(
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
        body: const TabBarView(
          children: [
            _PublicationsByYearTab(),
            _TopJournalsTab(),
            _TopPapersTab(),
            _TopAuthorsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Publications by Year ───────────────────────────────────────────────
class _PublicationsByYearTab extends StatelessWidget {
  const _PublicationsByYearTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final byYear = provider.publicationsByYear;

    if (byYear.isEmpty) {
      return const EmptyState(
          icon: Icons.bar_chart,
          title: 'No Data',
          subtitle: 'No year data available.');
    }

    final years = byYear.keys.toList();
    final maxCount =
        byYear.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _chartCard(context, byYear, years, maxCount),
          const SizedBox(height: 16),
          _trendInsights(context, byYear, years),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, Map<int, int> byYear,
      List<int> years, double maxCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
                title: 'Publications Over Time',
                subtitle: 'Number of publications per year'),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxCount * 1.2,
                  barGroups: years.asMap().entries.map((entry) {
                    final i = entry.key;
                    final year = entry.value;
                    final count = byYear[year]!.toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          width: years.length > 20 ? 6 : 14,
                          color: AppTheme.primary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppTheme.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: years.length > 15 ? 3 : 1,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= years.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${years[idx]}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final year = years[group.x];
                        return BarTooltipItem(
                          '$year\n${rod.toY.toInt()} papers',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendInsights(
      BuildContext context, Map<int, int> byYear, List<int> years) {
    final peakYear =
        byYear.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final totalPubs = byYear.values.fold<int>(0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Trend Insights'),
            const SizedBox(height: 16),
            _insightRow(context, 'Peak Year', '${peakYear.key}',
                '${peakYear.value} publications'),
            const Divider(height: 24),
            _insightRow(context, 'Year Range',
                '${years.first} – ${years.last}',
                '${years.last - years.first + 1} years of data'),
            const Divider(height: 24),
            _insightRow(context, 'Total Publications', '$totalPubs',
                'across all years'),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(
      BuildContext context, String label, String value, String sub) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Text(sub,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11)),
      ],
    );
  }
}

// ── Tab 2: Top Journals ───────────────────────────────────────────────────────
class _TopJournalsTab extends StatelessWidget {
  const _TopJournalsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final journals = provider.topJournals;

    if (journals.isEmpty) {
      return const EmptyState(
          icon: Icons.library_books,
          title: 'No Journal Data',
          subtitle: 'Could not extract journal information from results.');
    }

    final entries = journals.entries.toList();
    final maxVal = entries.first.value.toDouble();
    final total = journals.values.fold<int>(0, (s, v) => s + v);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                      title: 'Top Research Journals',
                      subtitle: 'By number of publications'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 320,
                    child: PieChart(
                      PieChartData(
                        sections: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          final pct = entry.value / total * 100;
                          return PieChartSectionData(
                            color: AppTheme.chartPalette[
                                i % AppTheme.chartPalette.length],
                            value: entry.value.toDouble(),
                            title:
                                i < 5 ? '${pct.toStringAsFixed(1)}%' : '',
                            radius: 100,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entries.asMap().entries.map((e) {
                      final color = AppTheme.chartPalette[
                          e.key % AppTheme.chartPalette.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            e.value.key.length > 25
                                ? '${e.value.key.substring(0, 25)}…'
                                : e.value.key,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final pct = entry.value / maxVal;
                return Padding(
                  padding: EdgeInsets.fromLTRB(16,
                      i == 0 ? 16 : 8, 16, i == entries.length - 1 ? 16 : 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: i < 3
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            )),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style:
                                    Theme.of(context).textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: AppTheme.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.chartPalette[
                                      i % AppTheme.chartPalette.length],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${entry.value}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Top Papers ─────────────────────────────────────────────────────────
class _TopPapersTab extends StatelessWidget {
  const _TopPapersTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final papers = provider.topInfluentialPapers;

    if (papers.isEmpty) {
      return const EmptyState(
          icon: Icons.article_outlined,
          title: 'No Papers',
          subtitle: 'No publication data available.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => PublicationCard(
        publication: papers[i],
        rank: i + 1,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PublicationDetailScreen(publication: papers[i]),
          ),
        ),
      ),
    );
  }
}

// ── Tab 4: Top Authors ────────────────────────────────────────────────────────
class _TopAuthorsTab extends StatelessWidget {
  const _TopAuthorsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final authors = provider.topAuthors;

    if (authors.isEmpty) {
      return const EmptyState(
          icon: Icons.people_outline,
          title: 'No Author Data',
          subtitle: 'Could not extract author information from results.');
    }

    final entries = authors.entries.toList();
    final maxVal = entries.first.value.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bar chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                      title: 'Top Contributing Authors',
                      subtitle: 'By number of publications'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 280,
                    child: BarChart(
                      BarChartData(
                        maxY: maxVal * 1.3,
                        barGroups: entries.asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                width: entries.length > 8 ? 10 : 18,
                                color: AppTheme.chartPalette[
                                    i % AppTheme.chartPalette.length],
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppTheme.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                '${v.toInt()}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= entries.length) {
                                  return const SizedBox();
                                }
                                final name = entries[idx].key;
                                // Show first name only to save space
                                final short = name.split(' ').first;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    short,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, _, rod, __) {
                              final name = entries[group.x].key;
                              return BarTooltipItem(
                                '$name\n${rod.toY.toInt()} papers',
                                const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ranked list
          Card(
            child: Column(
              children: entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final pct = entry.value / maxVal;
                final color = AppTheme.chartPalette[
                    i % AppTheme.chartPalette.length];

                return Padding(
                  padding: EdgeInsets.fromLTRB(16,
                      i == 0 ? 16 : 10, 16, i == entries.length - 1 ? 16 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 28,
                            height: 28,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: i < 3
                                      ? color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: color.withOpacity(0.15),
                            child: Text(
                              entry.key.isNotEmpty
                                  ? entry.key[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
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
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppTheme.divider,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      if (i < entries.length - 1) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}