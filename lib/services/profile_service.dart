import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileItem {
  const ProfileItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get title => data['title'] as String? ?? data['keyword'] as String? ?? data['displayName'] as String? ?? 'Untitled';
  String get authors => data['authors'] as String? ?? '';
  String get journal => data['journal'] as String? ?? '';
  String get year => '${data['year'] ?? ''}';
}

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.bookmarks,
    required this.favoriteJournals,
    required this.collections,
    required this.recentlyViewed,
    required this.searchHistory,
    required this.totalSearches,
    required this.feedbackSubmitted,
    required this.role,
    required this.status,
    required this.darkMode,
    required this.notifications,
  });

  final List<ProfileItem> bookmarks;
  final List<ProfileItem> favoriteJournals;
  final List<ProfileItem> collections;
  final List<ProfileItem> recentlyViewed;
  final List<ProfileItem> searchHistory;
  final int totalSearches;
  final int feedbackSubmitted;
  final String role;
  final String status;
  final bool darkMode;
  final bool notifications;
}

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ProfileSnapshot> load(User user) async {
    final userReference = _firestore.collection('users').doc(user.uid);
    final results = await Future.wait([
      userReference.collection('bookmarks').get(),
      userReference.collection('favorite_journals').get(),
      userReference.collection('collections').get(),
      userReference.get(),
      userReference.collection('settings').doc('preferences').get(),
      userReference.collection('search_history').orderBy('searchedAt', descending: true).limit(5).get(),
      userReference.collection('activity_logs').orderBy('timestamp', descending: true).limit(10).get(),
    ]);

    final profile = results[3] as DocumentSnapshot<Map<String, dynamic>>;
    final settings = results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final searchHistory = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final activity = results[6] as QuerySnapshot<Map<String, dynamic>>;
    final profileData = profile.data() ?? const <String, dynamic>{};
    final settingsData = settings.data() ?? const <String, dynamic>{};

    return ProfileSnapshot(
      bookmarks: _items(results[0]),
      favoriteJournals: _items(results[1]),
      collections: _items(results[2]),
      searchHistory: _items(searchHistory),
      recentlyViewed: _items(activity)
          .where((item) => item.data['action'] == 'view_publication')
          .toList(),
      totalSearches: (profileData['totalSearches'] as num?)?.toInt() ?? 0,
      feedbackSubmitted: await _feedbackCount(user.uid),
      role: profileData['role'] as String? ?? 'USER',
      status: profileData['status'] as String? ?? 'ACTIVE',
      darkMode: settingsData['darkMode'] as bool? ?? false,
      notifications: settingsData['notifications'] as bool? ?? true,
    );
  }

  Future<void> updateSetting(String uid, String key, bool value) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .set({key: value}, SetOptions(merge: true));
  }

  Future<void> removeBookmark(String uid, String bookmarkId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(bookmarkId)
        .delete();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> bookmarkStream(String uid, String workId) =>
      _firestore.collection('users').doc(uid).collection('bookmarks').doc(_docId(workId)).snapshots();

  Future<void> toggleBookmark({required String uid, required String workId, required Map<String, dynamic> data}) async {
    final reference = _firestore.collection('users').doc(uid).collection('bookmarks').doc(_docId(workId));
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        transaction.delete(reference);
      } else {
        transaction.set(reference, {
          ...data,
          'workId': workId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> favoriteJournalStream(String uid, String journalId) =>
      _firestore.collection('users').doc(uid).collection('favorite_journals').doc(_docId(journalId)).snapshots();

  Future<void> toggleFavoriteJournal({required String uid, required String journalId, required Map<String, dynamic> data}) async {
    final reference = _firestore.collection('users').doc(uid).collection('favorite_journals').doc(_docId(journalId));
    if ((await reference.get()).exists) {
      await reference.delete();
    } else {
      await reference.set({...data, 'journalId': journalId, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> recordSearch(String uid) {
    return _firestore.collection('users').doc(uid).set({
      'totalSearches': FieldValue.increment(1),
      'lastSearch': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordViewedPublication({required String uid, required String workId, required String title}) {
    return _firestore.collection('users').doc(uid).collection('activity_logs').add({
      'action': 'view_publication',
      'target': workId,
      'title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  List<ProfileItem> _items(Object result) {
    final snapshot = result as QuerySnapshot<Map<String, dynamic>>;
    return snapshot.docs
        .map((document) => ProfileItem(id: document.id, data: document.data()))
        .toList();
  }

  Future<int> _feedbackCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('feedback')
          .where('uid', isEqualTo: uid)
          .get();
      return snapshot.size;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return 0;
      rethrow;
    }
  }

  String _docId(String id) => id.split('/').last.replaceAll('/', '_');
}
