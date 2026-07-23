import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> user(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> userCollection(
    String uid,
    String collection,
  ) =>
      user(uid).collection(collection);

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _db.collection(name);

  WriteBatch batch() => _db.batch();

  Future<T> transaction<T>(Future<T> Function(Transaction transaction) action) =>
      _db.runTransaction(action);

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      user(uid).get(const GetOptions(source: Source.serverAndCache));

  Future<void> updateCounter(String uid, String field, int delta) => user(uid).set({
        field: FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
