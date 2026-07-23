import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/profile_service.dart';
import '../theme.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/firestore_viewmodels.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late Future<ProfileSnapshot> _profileFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AuthViewModel>().currentUser;
    _profileFuture = user == null
        ? Future.error('No signed-in user')
        : ProfileService().load(user);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthViewModel>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ProfileSnapshot>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 280),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 220),
                const Center(child: Text('Unable to load your dashboard.')),
                Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
              ]);
            }
            return _DashboardContent(
              user: user,
              snapshot: snapshot.data!,
              onNavigate: widget.onNavigate,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.user, required this.snapshot, required this.onNavigate});

  final User user;
  final ProfileSnapshot snapshot;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim().isNotEmpty == true ? user.displayName! : 'Researcher';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(_greeting(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),
        Text(name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        const _SectionTitle('Your overview'),
        _StatsGrid(snapshot: snapshot),
        const SizedBox(height: 24),
        const _SectionTitle('Quick actions'),
        _QuickActions(onNavigate: onNavigate),
        const SizedBox(height: 24),
        const _SectionTitle('Recently viewed'),
        _RecentItems(items: snapshot.recentlyViewed),
        const SizedBox(height: 24),
        const _SectionTitle('Recommended topics'),
        _Recommendations(snapshot: snapshot),
        const SizedBox(height: 24),
        const _SectionTitle('Recent notifications'),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(user.uid),
          child: const _NotificationList(),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.snapshot});
  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 5 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          _StatTile('Bookmarks', snapshot.bookmarks.length, Icons.bookmark_outline),
          _StatTile('Journals', snapshot.favoriteJournals.length, Icons.favorite_outline),
          _StatTile('Searches', snapshot.totalSearches, Icons.search),
          _StatTile('Collections', snapshot.collections.length, Icons.folder_outlined),
          _StatTile('Feedback', snapshot.feedbackSubmitted, Icons.feedback_outlined),
        ],
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Action('Search Journal', Icons.menu_book_outlined, () => onNavigate(1)),
          _Action('Research Trend', Icons.insights_outlined, () => onNavigate(2)),
          _Action('Bookmarks', Icons.bookmark_outline, () => onNavigate(3)),
          _Action('Collections', Icons.folder_outlined, () => onNavigate(3)),
          _Action('Feedback', Icons.feedback_outlined, () => onNavigate(3)),
        ],
      );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
}

class _RecentItems extends StatelessWidget {
  const _RecentItems({required this.items});
  final List<ProfileItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyPanel('No saved papers yet.');
    return Card(child: Column(children: items.take(3).map((item) => ListTile(
      leading: const Icon(Icons.article_outlined),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text([item.journal, item.year].where((value) => value.isNotEmpty).join(' • ')),
    )).toList()));
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.snapshot});
  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final topics = <String>{
      ...snapshot.favoriteJournals.map((item) => item.title),
      ...snapshot.bookmarks.map((item) => item.journal).where((item) => item.isNotEmpty),
    }.take(5).toList();
    if (topics.isEmpty) return const _EmptyPanel('Search or save research to get recommendations.');
    return Wrap(spacing: 8, runSpacing: 8, children: topics.map((topic) => Chip(avatar: const Icon(Icons.auto_awesome, size: 16), label: Text(topic))).toList());
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<NotificationViewModel>();
    if (model.errorMessage != null) return const _EmptyPanel('Unable to load notifications.');
    if (model.notifications.isEmpty) return const _EmptyPanel('No recent notifications.');
    return Card(child: Column(children: model.notifications.take(3).map((item) => ListTile(
      leading: const Icon(Icons.notifications_none),
      title: Text(item.data['title'] as String? ?? 'Notification'),
      subtitle: Text(item.data['body'] as String? ?? ''),
    )).toList()));
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(message)));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}
