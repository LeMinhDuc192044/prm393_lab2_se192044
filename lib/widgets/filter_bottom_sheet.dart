import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_filter.dart';
import '../providers/search_provider.dart';
import '../theme.dart';

/// Shows the filter bottom sheet. Call this from any screen.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<SearchProvider>(),
      child: const _FilterSheet(),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _authorController = TextEditingController();
  final _journalController = TextEditingController();

  late int _yearFrom;
  late int _yearTo;
  String? _selectedField;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SearchProvider>();
    final filter = provider.filter;

    // Pre-populate with existing filter values
    _authorController.text = filter.author ?? '';
    _journalController.text = filter.journal ?? '';
    _yearFrom = filter.yearFrom ?? provider.minYear;
    _yearTo = filter.yearTo ?? provider.maxYear;
    _selectedField = filter.field;
  }

  @override
  void dispose() {
    _authorController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _apply() {
    final provider = context.read<SearchProvider>();
    provider.applyFilter(SearchFilter(
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      yearFrom: _yearFrom == provider.minYear ? null : _yearFrom,
      yearTo: _yearTo == provider.maxYear ? null : _yearTo,
      journal: _journalController.text.trim().isEmpty
          ? null
          : _journalController.text.trim(),
      field: _selectedField,
    ));
    Navigator.pop(context);
  }

  void _clear() {
    context.read<SearchProvider>().clearFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final minYear = provider.minYear;
    final maxYear = provider.maxYear;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Filter Publications',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear all',
                      style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Author ───────────────────────────────────────────────────────
            _label(context, Icons.person_outline, 'Author'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _authorController.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return [];
                final q = textEditingValue.text.toLowerCase();
                return provider.availableAuthors
                    .where((a) => a.toLowerCase().contains(q))
                    .take(6);
              },
              onSelected: (val) => _authorController.text = val,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                // Sync our controller with the autocomplete controller
                controller.text = _authorController.text;
                controller.addListener(() {
                  _authorController.text = controller.text;
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration('Search by author name...'),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Year Range ───────────────────────────────────────────────────
            _label(context, Icons.calendar_today_outlined, 'Year Range'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$_yearFrom',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$_yearTo',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
            RangeSlider(
              values: RangeValues(
                _yearFrom.toDouble(),
                _yearTo.toDouble(),
              ),
              min: minYear.toDouble(),
              max: maxYear.toDouble(),
              divisions: (maxYear - minYear).clamp(1, 100),
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.divider,
              onChanged: (values) {
                setState(() {
                  _yearFrom = values.start.round();
                  _yearTo = values.end.round();
                });
              },
            ),
            const SizedBox(height: 20),

            // ── Journal ──────────────────────────────────────────────────────
            _label(context, Icons.library_books_outlined, 'Journal'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _journalController.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return [];
                final q = textEditingValue.text.toLowerCase();
                return provider.availableJournals
                    .where((j) => j.toLowerCase().contains(q))
                    .take(6);
              },
              onSelected: (val) => _journalController.text = val,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                controller.text = _journalController.text;
                controller.addListener(() {
                  _journalController.text = controller.text;
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration('Search by journal name...'),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Research Field / Major ────────────────────────────────────────
            _label(context, Icons.school_outlined, 'Research Field / Major'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedField,
              hint: const Text('Select a field...'),
              decoration: _inputDecoration(null),
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All fields',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ...SearchFilter.researchFields.map(
                  (f) => DropdownMenuItem(value: f, child: Text(f)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedField = val),
            ),
            const SizedBox(height: 28),

            // ── Apply Button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check),
                label: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}
