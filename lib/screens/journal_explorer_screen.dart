import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import 'journal_screen.dart';

class JournalExplorerScreen extends StatefulWidget {
  const JournalExplorerScreen({super.key});

  @override
  State<JournalExplorerScreen> createState() => _JournalExplorerScreenState();
}

class _JournalExplorerScreenState extends State<JournalExplorerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _search() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) context.read<SearchProvider>().search(query);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Journal Explorer')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(labelText: 'Search journals', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward))),
            ),
          ),
          const Expanded(child: JournalScreen()),
        ]),
      );
}
