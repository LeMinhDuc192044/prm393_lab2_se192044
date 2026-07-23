import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../viewmodels/admin_dashboard_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'admin_user_detail_screen.dart';

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
        return _Notifications(model: model);
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
                _StreamMetric(label: 'Feedback', stream: model.feedback, icon: Icons.feedback_outlined),
                _StreamMetric(label: 'Reports', stream: model.reports, icon: Icons.report_outlined),
                _StreamMetric(label: 'Notifications', stream: model.notifications, icon: Icons.notifications_outlined),
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

class _StreamMetric extends StatelessWidget {
  const _StreamMetric({required this.label, required this.stream, required this.icon});
  final String label;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final IconData icon;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) => _Metric(label: label, value: snapshot.data?.size ?? 0, icon: icon),
      );
}

class _Users extends StatefulWidget {
  const _Users({required this.model});
  final AdminDashboardViewModel model;

  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
  }
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.model.users,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load users: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final query = _searchController.text.trim().toLowerCase();
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final matchesText = query.isEmpty ||
                '${data['displayName'] ?? ''} ${data['email'] ?? ''}'.toLowerCase().contains(query);
            final matchesStatus = _statusFilter == 'ALL' || data['status'] == _statusFilter;
            return matchesText && matchesStatus;
          }).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Expanded(child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search users'))),
                    const SizedBox(width: 8),
                    DropdownButton<String>(value: _statusFilter, items: const [DropdownMenuItem(value: 'ALL', child: Text('All')), DropdownMenuItem(value: 'ACTIVE', child: Text('Active')), DropdownMenuItem(value: 'DISABLED', child: Text('Disabled'))], onChanged: (value) => setState(() => _statusFilter = value ?? 'ALL')),
                  ]),
                );
              }
              final doc = docs[index - 1];
              final data = doc.data();
              final disabled = data['status'] == 'DISABLED';
              return Card(child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(uid: doc.id, data: data, model: widget.model))),
                leading: CircleAvatar(child: Text((data['displayName'] as String? ?? data['email'] as String? ?? '?').substring(0, 1).toUpperCase())),
                title: Text(data['displayName'] as String? ?? 'Unnamed user'),
                subtitle: Text('${data['email'] ?? ''}\n${data['role'] ?? 'USER'} • ${data['status'] ?? 'ACTIVE'}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    final isRole = value == 'role';
                    final next = isRole
                        ? (data['role'] == 'ADMIN' ? 'USER' : 'ADMIN')
                        : (disabled ? 'ACTIVE' : 'DISABLED');
                    final confirmed = await _confirm(
                      context,
                      isRole ? 'Change role?' : 'Change account status?',
                      'Apply $next to ${data['email'] ?? 'this user'}?',
                    );
                    if (!confirmed) return;
                    if (isRole) {
                      await widget.model.updateRole(doc.id, next);
                    } else {
                      await widget.model.updateStatus(doc.id, next);
                    }
                  },
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
                  if (onStatus != null) PopupMenuButton<String>(onSelected: (status) async { final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('Set status to $status?'), content: const Text('Confirm this moderation action.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))])); if (ok == true) await onStatus!(doc.id, status); }, itemBuilder: (_) => const [PopupMenuItem(value: 'APPROVED', child: Text('Approve')), PopupMenuItem(value: 'REJECTED', child: Text('Reject')), PopupMenuItem(value: 'RESOLVED', child: Text('Resolve'))]),
                  if (onDelete != null) IconButton(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('Delete $title?'), content: const Text('This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])); if (ok == true) await onDelete!(doc.id); }, icon: const Icon(Icons.delete_outline)),
                ]),
              ));
            }).toList(),
          );
        },
      );
}

class _Notifications extends StatelessWidget {
  const _Notifications({required this.model});
  final AdminDashboardViewModel model;

  Future<void> _openForm(BuildContext context, {String? id, Map<String, dynamic>? data}) async {
    final title = TextEditingController(text: data?['title'] as String? ?? '');
    final body = TextEditingController(text: data?['body'] as String? ?? '');
    var role = data?['targetRole'] as String? ?? 'USER';
    var active = data?['isActive'] as bool? ?? true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: Text(id == null ? 'Create notification' : 'Edit notification'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: body, decoration: const InputDecoration(labelText: 'Body'), maxLines: 3),
          DropdownButtonFormField<String>(initialValue: role, items: const [DropdownMenuItem(value: 'USER', child: Text('Users')), DropdownMenuItem(value: 'ADMIN', child: Text('Admins'))], onChanged: (value) => setState(() => role = value ?? 'USER')),
          SwitchListTile(title: const Text('Active'), value: active, onChanged: (value) => setState(() => active = value)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: title.text.trim().isEmpty || body.text.trim().isEmpty ? null : () => Navigator.pop(context, true), child: const Text('Save'))],
      )),
    );
    if (result != true) return;
    final payload = {'title': title.text.trim(), 'body': body.text.trim(), 'targetRole': role, 'isActive': active};
    if (id == null) {
      await model.createNotification(payload);
    } else {
      await model.updateNotification(id, payload);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: model.notifications,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load notifications: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(16), children: [
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _openForm(context), icon: const Icon(Icons.add), label: const Text('Create'))),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data();
              return Card(
                child: ListTile(
                  title: Text(data['title'] as String? ?? 'Untitled'),
                  subtitle: Text(data['body'] as String? ?? ''),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Edit notification',
                        onPressed: () => _openForm(context, id: doc.id, data: data),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete notification',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete notification?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await model.deleteNotification(doc.id);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]);
        },
      );
}
