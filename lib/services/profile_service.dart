import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileItem {
  const ProfileItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get title => data['title'] as String? ?? data['displayName'] as String? ?? 'Untitled';
  String get authors => data['authors'] as String? ?? '';
  String get journal => data['journal'] as String? ?? '';
  String get year => '${data['year'] ?? ''}';
}

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.bookmarks,
    required this.favoriteJournals,
    required this.collections,
    required this.totalSearches,
    required this.darkMode,
    required this.notifications,
  });

  final List<ProfileItem> bookmarks;
  final List<ProfileItem> favoriteJournals;
  final List<ProfileItem> collections;
  final int totalSearches;
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
    ]);

    final profile = results[3] as DocumentSnapshot<Map<String, dynamic>>;
    final settings = results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final profileData = profile.data() ?? const <String, dynamic>{};
    final settingsData = settings.data() ?? const <String, dynamic>{};

    return ProfileSnapshot(
      bookmarks: _items(results[0]),
      favoriteJournals: _items(results[1]),
      collections: _items(results[2]),
      totalSearches: (profileData['totalSearches'] as num?)?.toInt() ?? 0,
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
    if ((await reference.get()).exists) {
      await reference.delete();
    } else {
      await reference.set({...data, 'workId': workId, 'addedAt': FieldValue.serverTimestamp()});
    }
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

  List<ProfileItem> _items(Object result) {
    final snapshot = result as QuerySnapshot<Map<String, dynamic>>;
    return snapshot.docs
        .map((document) => ProfileItem(id: document.id, data: document.data()))
        .toList();
  }

  String _docId(String id) => id.split('/').last.replaceAll('/', '_');
}
