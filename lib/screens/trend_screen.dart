import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../widgets/common_widgets.dart';
import 'trend_analysis_screen.dart';

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _analyze() {
    final keyword = _controller.text.trim();
    if (keyword.isNotEmpty) context.read<SearchProvider>().search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Research Trend')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _analyze(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Analyze one keyword',
              prefixIcon: const Icon(Icons.insights_outlined),
              suffixIcon: IconButton(
                onPressed: _analyze,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        Expanded(
          child: provider.status == SearchStatus.loading
              ? const ShimmerList()
              : provider.status == SearchStatus.error
                  ? ErrorDisplay(message: provider.errorMessage, onRetry: _analyze)
                  : provider.hasData
                      ? const DefaultTabController(length: 4, child: Column(children: [
                          Material(color: Colors.transparent, child: TabBar(isScrollable: true, tabs: [Tab(text: 'By Year'), Tab(text: 'Journals'), Tab(text: 'Papers'), Tab(text: 'Authors')])),
                          Expanded(child: TrendAnalysisBody()),
                        ]))
                      : const EmptyState(icon: Icons.insights_outlined, title: 'Analyze a research topic', subtitle: 'Enter one keyword to view publication trends and related insights.'),
        ),
      ]),
    );
  }
}
