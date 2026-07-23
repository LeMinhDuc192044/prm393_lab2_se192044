import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../viewmodels/admin_dashboard_view_model.dart';
import '../viewmodels/auth_view_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _section = 0;
  static const _titles = ['Dashboard', 'Users', 'Feedback', 'Reports', 'Notifications'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardViewModel(),
      child: Consumer<AdminDashboardViewModel>(
        builder: (context, model, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Admin / ${_titles[_section]}'),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => context.read<AuthViewModel>().signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _section,
                  onDestinationSelected: (value) => setState(() => _section = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
                    NavigationRailDestination(icon: Icon(Icons.feedback_outlined), selectedIcon: Icon(Icons.feedback), label: Text('Feedback')),
                    NavigationRailDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: Text('Reports')),
                    NavigationRailDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: Text('Notifications')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _body(model)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(AdminDashboardViewModel model) {
    switch (_section) {
      case 1:
        return _Users(model: model);
      case 2:
        return _ModerationList(title: 'Feedback', stream: model.feedback, onStatus: model.updateFeedback, onDelete: model.deleteFeedback);
      case 3:
        return _ModerationList(title: 'Reports', stream: model.reports, onStatus: model.updateReport);
      case 4:
        return _ModerationList(title: 'Notifications', stream: model.notifications);
      default:
        return _Dashboard(model: model);
    }
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.model});
  final AdminDashboardViewModel model;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: model.users,
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final active = docs.where((doc) => doc.data()['status'] != 'DISABLED').length;
          final disabled = docs.length - active;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _Metric(label: 'Total users', value: docs.length, icon: Icons.people),
                _Metric(label: 'Active users', value: active, icon: Icons.verified_user),
                _Metric(label: 'Disabled users', value: disabled, icon: Icons.block),
              ]),
              const SizedBox(height: 24),
              const Text('Admin manages application data stored in Firestore. OpenAlex remains the source of research metadata.'),
            ],
          );
        },
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 190,
        child: Card(child: ListTile(leading: Icon(icon, color: AppTheme.primary), title: Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), subtitle: Text(label))),
      );
}

class _Users extends StatelessWidget {
  const _Users({required this.model});
  final AdminDashboardViewModel model;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: model.users,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load users: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data();
              final disabled = data['status'] == 'DISABLED';
              return Card(child: ListTile(
                leading: CircleAvatar(child: Text((data['displayName'] as String? ?? data['email'] as String? ?? '?').substring(0, 1).toUpperCase())),
                title: Text(data['displayName'] as String? ?? 'Unnamed user'),
                subtitle: Text('${data['email'] ?? ''}\n${data['role'] ?? 'USER'} • ${data['status'] ?? 'ACTIVE'}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => value == 'role' ? model.updateRole(doc.id, data['role'] == 'ADMIN' ? 'USER' : 'ADMIN') : model.updateStatus(doc.id, disabled ? 'ACTIVE' : 'DISABLED'),
                  itemBuilder: (_) => [PopupMenuItem(value: 'role', child: Text(data['role'] == 'ADMIN' ? 'Make user' : 'Make admin')), PopupMenuItem(value: 'status', child: Text(disabled ? 'Enable' : 'Disable'))],
                ),
              ));
            },
          );
        },
      );
}

class _ModerationList extends StatelessWidget {
  const _ModerationList({required this.title, required this.stream, this.onStatus, this.onDelete});
  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<void> Function(String, String)? onStatus;
  final Future<void> Function(String)? onDelete;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load $title: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No $title yet.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((doc) {
              final data = doc.data();
              return Card(child: ListTile(
                title: Text(data['title'] as String? ?? data['message'] as String? ?? data['description'] as String? ?? title),
                subtitle: Text('${data['status'] ?? 'PENDING'} • ${data['uid'] ?? ''}'),
                trailing: Wrap(children: [
                  if (onStatus != null) PopupMenuButton<String>(onSelected: (status) => onStatus!(doc.id, status), itemBuilder: (_) => const [PopupMenuItem(value: 'APPROVED', child: Text('Approve')), PopupMenuItem(value: 'REJECTED', child: Text('Reject')), PopupMenuItem(value: 'RESOLVED', child: Text('Resolve'))]),
                  if (onDelete != null) IconButton(onPressed: () => onDelete!(doc.id), icon: const Icon(Icons.delete_outline)),
                ]),
              ));
            }).toList(),
          );
        },
      );
}
