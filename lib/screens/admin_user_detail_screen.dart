import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../viewmodels/admin_dashboard_view_model.dart';

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.uid, required this.data, required this.model});

  final String uid;
  final Map<String, dynamic> data;
  final AdminDashboardViewModel model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: Text(data['displayName'] as String? ?? 'Unnamed user'), subtitle: Text('${data['email'] ?? ''}\nUID: $uid\nRole: ${data['role'] ?? 'USER'}\nStatus: ${data['status'] ?? 'ACTIVE'}'))),
          const SizedBox(height: 16),
          _subcollection('Bookmarks', 'bookmarks'),
          _subcollection('Favorite Journals', 'favorite_journals'),
          _subcollection('Collections', 'collections'),
          _subcollection('Search History', 'search_history'),
          _subcollection('Activity Logs', 'activity_logs'),
        ],
      ),
    );
  }

  Widget _subcollection(String title, String name) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: model.userCollection(uid, name),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return Card(
          child: ExpansionTile(
            title: Text('$title (${docs.length})'),
            children: docs.isEmpty
                ? const [ListTile(title: Text('No records'))]
                : docs.take(20).map((doc) => ListTile(title: Text('${doc.data()['title'] ?? doc.data()['action'] ?? doc.id}'))).toList(),
          ),
        );
      },
    );
  }
}
