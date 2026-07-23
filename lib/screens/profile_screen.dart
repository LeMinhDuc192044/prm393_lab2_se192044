import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/profile_service.dart';
import '../theme.dart';
import '../viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late Future<ProfileSnapshot> _profileFuture;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _profileFuture = user == null
        ? Future.error('No signed-in user')
        : _profileService.load(user);
  }

  void _reload() {
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      setState(() => _profileFuture = _profileService.load(user));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No signed-in user'))
          : FutureBuilder<ProfileSnapshot>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _reload);
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ProfileHeader(user: user),
                      const SizedBox(height: 16),
                      const _SectionTitle(title: 'My Statistics'),
                      _Statistics(snapshot: snapshot.data!),
                      const SizedBox(height: 20),
                      _Bookmarks(
                        items: snapshot.data!.bookmarks,
                        onRemove: (id) async {
                          await _profileService.removeBookmark(user.uid, id);
                          _reload();
                        },
                      ),
                      const SizedBox(height: 20),
                      _Favorites(items: snapshot.data!.favoriteJournals),
                      const SizedBox(height: 20),
                      _Settings(
                        snapshot: snapshot.data!,
                        onChanged: (key, value) async {
                          await _profileService.updateSetting(user.uid, key, value);
                          _reload();
                        },
                      ),
                      const SizedBox(height: 20),
                      _DeveloperCard(onCrash: _crash),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.read<AuthViewModel>().signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _crash() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crashlytics test is available on Android/iOS.')),
      );
      return;
    }
    FirebaseCrashlytics.instance.crash();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final provider = user.providerData.isEmpty
        ? 'Email & Password'
        : user.providerData.first.providerId == 'google.com'
            ? 'Google'
            : 'Email & Password';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage:
                  user.photoURL == null ? null : NetworkImage(user.photoURL!),
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(user.displayName ?? 'User', style: Theme.of(context).textTheme.titleLarge),
            Text(user.email ?? 'No email'),
            const SizedBox(height: 12),
            _InfoLine(label: 'Provider', value: provider),
            _InfoLine(label: 'UID', value: user.uid),
            _InfoLine(label: 'Created', value: _formatDate(user.metadata.creationTime)),
            _InfoLine(label: 'Last login', value: _formatDate(user.metadata.lastSignInTime)),
          ],
        ),
      ),
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.snapshot});

  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Favorites', value: snapshot.favoriteJournals.length, icon: Icons.favorite),
            _Stat(label: 'Bookmarks', value: snapshot.bookmarks.length, icon: Icons.bookmark),
            _Stat(label: 'Collections', value: snapshot.collections.length, icon: Icons.folder),
            _Stat(label: 'Searches', value: snapshot.totalSearches, icon: Icons.search),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}

class _Bookmarks extends StatelessWidget {
  const _Bookmarks({required this.items, required this.onRemove});
  final List<ProfileItem> items;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) => _ItemSection(
        title: 'Bookmarks',
        icon: Icons.bookmark_outline,
        items: items,
        trailing: (item) => IconButton(
          tooltip: 'Remove bookmark',
          onPressed: () => onRemove(item.id),
          icon: const Icon(Icons.delete_outline),
        ),
      );
}

class _Favorites extends StatelessWidget {
  const _Favorites({required this.items});
  final List<ProfileItem> items;

  @override
  Widget build(BuildContext context) => _ItemSection(
        title: 'Favorite Journals',
        icon: Icons.favorite_outline,
        items: items,
      );
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({required this.title, required this.icon, required this.items, this.trailing});
  final String title;
  final IconData icon;
  final List<ProfileItem> items;
  final Widget Function(ProfileItem item)? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, icon: icon),
          Card(
            child: items.isEmpty
                ? const ListTile(title: Text('Nothing saved yet'))
                : Column(
                    children: items.map((item) => ListTile(
                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text([item.authors, item.journal, item.year].where((v) => v.isNotEmpty).join(' • ')),
                          trailing: trailing?.call(item),
                        )).toList(),
                  ),
          ),
        ],
      );
}

class _Settings extends StatelessWidget {
  const _Settings({required this.snapshot, required this.onChanged});
  final ProfileSnapshot snapshot;
  final Future<void> Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Settings', icon: Icons.settings_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: snapshot.darkMode,
                  onChanged: (value) => onChanged('darkMode', value),
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  value: snapshot.notifications,
                  onChanged: (value) => onChanged('notifications', value),
                ),
              ],
            ),
          ),
        ],
      );
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.onCrash});
  final VoidCallback onCrash;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.developer_mode_outlined),
          title: const Text('Developer'),
          subtitle: const Text('Send a test crash to Crashlytics'),
          trailing: FilledButton(
            onPressed: onCrash,
            child: const Text('Test'),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load profile data.'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

String _formatDate(DateTime? date) {
  return date == null ? 'Not available' : DateFormat.yMMMd().add_jm().format(date);
}
