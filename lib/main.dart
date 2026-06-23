import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const JournalTrendAnalyzerApp());
}

class JournalTrendAnalyzerApp extends StatelessWidget {
  const JournalTrendAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),  
      child: MaterialApp(
        title: 'Journal Trend Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}