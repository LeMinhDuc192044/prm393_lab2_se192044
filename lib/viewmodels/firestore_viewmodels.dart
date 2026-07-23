import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/firestore_models.dart';
import '../repositories/firestore_repositories.dart';

class FirestoreListViewModel extends ChangeNotifier {
  FirestoreListViewModel(Stream<List<FirestoreItem>> stream) : _stream = stream {
    _subscription = _stream.listen(
      (items) {
        data = items;
        loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        loading = false;
        errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  final Stream<List<FirestoreItem>> _stream;
  late final StreamSubscription<List<FirestoreItem>> _subscription;

  bool loading = true;
  String? errorMessage;
  List<FirestoreItem> data = const [];

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class BookmarkViewModel extends FirestoreListViewModel {
  BookmarkViewModel(String uid) : super(BookmarkRepository(uid).watch());
}

class FavoriteViewModel extends FirestoreListViewModel {
  FavoriteViewModel(String uid) : super(FavoriteRepository(uid).watch());
}

class CollectionViewModel extends FirestoreListViewModel {
  CollectionViewModel(String uid) : super(CollectionRepository(uid).watch());
}

class SearchHistoryViewModel extends FirestoreListViewModel {
  SearchHistoryViewModel(String uid) : super(SearchRepository(uid).watch());
}

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this.uid);
  final String uid;
  bool loading = false;
  String? errorMessage;
  late final SettingsRepository _repository = SettingsRepository(uid);

  Future<void> update(String key, bool value) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.save('preferences', {key: value});
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(String uid) {
    _subscription = NotificationRepository(uid).watchActive().listen((snapshot) {
      notifications = snapshot.docs.map((doc) => FirestoreItem(
        id: doc.id,
        data: doc.data(),
      )).toList();
      notifyListeners();
    }, onError: (Object error) {
      errorMessage = error.toString();
      notifyListeners();
    });
  }

  late final StreamSubscription _subscription;
  List<FirestoreItem> notifications = const [];
  String? errorMessage;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class FeedbackViewModel extends ChangeNotifier {
  FeedbackViewModel(this.uid);
  final String uid;
  bool loading = false;
  String? errorMessage;

  Future<void> submit(Map<String, dynamic> data) async {
    loading = true;
    notifyListeners();
    try {
      await FeedbackRepository(uid).create(data);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
